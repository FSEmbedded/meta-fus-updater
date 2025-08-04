import argparse
import subprocess
from pathlib import Path
import datetime
import binascii
import logging
from typing import Optional, Tuple

try:
    from Crypto.Hash      import SHA256
    from Crypto.Signature import pss
    from Crypto.PublicKey import RSA
    NAMESPACE = "Crypto"
except ImportError:
    # Fallback depends on the environment, e.g., Debian Bookworm uses Cryptodome
    from Cryptodome.Hash      import SHA256
    from Cryptodome.Signature import pss
    from Cryptodome.PublicKey import RSA
    NAMESPACE = "Cryptodome"


class Config:
    """Configuration constants for the image signer"""
    CHUNK_SIZE = 1024
    HEADER_VERSION = 1
    TIMESTAMP_SIZE = 26  # "YYYY-MM-DDTHH:MM:SSZ" is exactly 26 bytes
    HEADER_SIZE_BYTES = 8
    HEADER_VERSION_BYTES = 4
    HEADER_CRC_BYTES = 4
    MKSQUASHFS_TIMEOUT = 300
    UNSIGNED_IMAGE_POSTFIX = "_unsigned"


class ImageSigner:
    """SquashFS image creation and signing utility"""

    def __init__(self, chunk_size: int = Config.CHUNK_SIZE):
        self.chunk_size = chunk_size
        self.logger = logging.getLogger(__name__)

    def validate_inputs(self, args: argparse.Namespace) -> None:
        """Validate command line arguments"""
        if args.root_folder and not args.root_folder.exists():
            raise ValueError(f"Root folder does not exist: {args.root_folder}")

        if not args.key_file.exists():
            raise ValueError(f"Key file does not exist: {args.key_file}")

        if args.root_folder and args.mksquashfs_path and not args.mksquashfs_path.exists():
            raise ValueError(f"mksquashfs binary not found: {args.mksquashfs_path}")

        if args.cert_file and not args.cert_file.exists():
            self.logger.warning(f"Certificate file does not exist: {args.cert_file}")

    def create_squashfs(self, root: Path, temp_img: Path, mksquashfs: Path) -> None:
        """Create SquashFS image from root directory"""
        # Remove temporary image if it exists
        temp_img.unlink(missing_ok=True)

        # Build mksquashfs command
        cmd = [
            str(mksquashfs), str(root), str(temp_img),
            '-all-root', '-force-uid', '0', '-force-gid', '0'
        ]

        self.logger.info(f"Creating SquashFS image: {' '.join(cmd)}")

        try:
            result = subprocess.run(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=True,
                timeout=Config.MKSQUASHFS_TIMEOUT
            )
            self.logger.info("SquashFS creation completed successfully")

        except subprocess.CalledProcessError as e:
            stderr = e.stderr.decode().strip() if e.stderr else "Unknown error"
            raise RuntimeError(f"mksquashfs failed: {stderr}")
        except subprocess.TimeoutExpired:
            raise RuntimeError(f"mksquashfs timed out after {Config.MKSQUASHFS_TIMEOUT} seconds")

    def compute_header_and_signature(self, img_path: Path, private_key: RSA.RsaKey) -> Tuple[bytes, bytes]:
        """Compute header and signature for the image"""
        # Get filesystem image size
        try:
            size = img_path.stat().st_size
            self.logger.info(f"Image size: {size} bytes")
        except OSError as e:
            raise RuntimeError(f"Failed to get image size: {e}")

        # Construct header: [size (8 bytes) | version (4 bytes) | crc32 (4 bytes)]
        size_bytes = size.to_bytes(Config.HEADER_SIZE_BYTES, 'big')
        version_bytes = Config.HEADER_VERSION.to_bytes(Config.HEADER_VERSION_BYTES, 'big')
        crc_input = size_bytes + version_bytes
        crc32_bytes = binascii.crc32(crc_input).to_bytes(Config.HEADER_CRC_BYTES, 'big')

        header = size_bytes + version_bytes + crc32_bytes

        # Generate timestamp in ISO 8601 format: "YYYY-MM-DDTHH:MM:SSZ"
        timestamp_str = datetime.datetime.utcnow().replace(microsecond=0).isoformat(timespec='seconds') + 'Z'
        timestamp_bytes = timestamp_str.encode('ascii')

        if len(timestamp_bytes) > Config.TIMESTAMP_SIZE:
            raise ValueError(f"Timestamp too long ({len(timestamp_bytes)} > {Config.TIMESTAMP_SIZE}): {timestamp_str}")

        timestamp_block = timestamp_bytes.ljust(Config.TIMESTAMP_SIZE, b'\0')

        # Compute SHA-256 over image content and timestamp
        hasher = SHA256.new()

        try:
            with img_path.open('rb') as f:
                while chunk := f.read(self.chunk_size):
                    hasher.update(chunk)
        except IOError as e:
            raise RuntimeError(f"Failed to read image file: {e}")

        hasher.update(timestamp_block)

        digest_hex = hasher.hexdigest()
        self.logger.info(f"Final digest (hex): {digest_hex}")

        # Sign the hash
        try:
            signature = pss.new(private_key).sign(hasher)
            self.logger.info(f"Signature generated, size: {len(signature)} bytes")
        except Exception as e:
            raise RuntimeError(f"Failed to generate signature: {e}")

        return header, timestamp_block + signature

    def append_cert_chain(self, out_file: Path, cert_file: Optional[Path]) -> None:
        """Append certificate chain if provided and exists"""
        if cert_file and cert_file.exists():
            try:
                data = cert_file.read_bytes()
                with out_file.open('ab') as f:
                    f.write(b"\n")
                    f.write(data)
                self.logger.info(f"Certificate chain appended from: {cert_file}")
            except IOError as e:
                self.logger.error(f"Failed to append certificate chain: {e}")
                raise
        elif cert_file:
            self.logger.warning(f"Certificate file not found: {cert_file}")

    def load_private_key(self, key_file: Path) -> RSA.RsaKey:
        """Load and import private key with normalization"""
        try:
            key_bytes = key_file.read_bytes()
            self.logger.info(f"Loaded key file: {key_file}")
        except IOError as e:
            raise RuntimeError(f"Failed to read key file: {e}")

        # Try to import key as-is first
        try:
            return RSA.import_key(key_bytes)
        except ValueError:
            # Normalize line endings and try again
            normalized = key_bytes.replace(b'\r\n', b'\n').replace(b'\r', b'\n')
            try:
                return RSA.import_key(normalized)
            except ValueError as e:
                raise RuntimeError(f"Failed to import private key '{key_file}': {e}")

    def write_version_file(self, root_folder: Path, version: str) -> None:
        """Write version file to the root folder"""
        version_file = root_folder / 'etc' / 'app_version'
        try:
            version_file.parent.mkdir(parents=True, exist_ok=True)
            version_file.write_text(version)
            self.logger.info(f"Version file written: {version_file}")
        except IOError as e:
            raise RuntimeError(f"Failed to write version file: {e}")

    def create_signed_image(self, args: argparse.Namespace) -> None:
        """Main method to create and sign image"""
        self.validate_inputs(args)

        # Generate image paths based on output pattern
        base_path = args.output_image
        base_name = base_path.stem
        base_dir = base_path.parent
        suffix = base_path.suffix

        # Create unsigned squashfs image path with postfix
        unsigned_img = base_dir / f"{base_name}{Config.UNSIGNED_IMAGE_POSTFIX}{suffix}"  # application_unsigned.squashfs

        # Create signed image path (final output at -o parameter)
        signed_img = base_path  # application.squashfs

        in_place = args.sign_image and args.sign_image.resolve() == signed_img.resolve()

        if not in_place:
            signed_img.unlink(missing_ok=True)

        # Remove existing unsigned image
        unsigned_img.unlink(missing_ok=True)

        # Build or prepare unsigned image
        if args.root_folder:
            if not args.mksquashfs_path or not args.version:
                raise ValueError("--mksquashfs-path and --version are required when creating a new image from --root-folder")

            # Write version file and create unsigned SquashFS image
            self.write_version_file(args.root_folder, args.version)
            self.create_squashfs(args.root_folder, unsigned_img, args.mksquashfs_path)
            self.logger.info(f"Unsigned SquashFS image created: {unsigned_img}")
        else:
            if not args.sign_image.exists():
                raise ValueError(f"Input file '{args.sign_image}' not found")
            # Copy existing image to unsigned_img if different paths
            if args.sign_image.resolve() != unsigned_img.resolve():
                import shutil
                shutil.copy2(args.sign_image, unsigned_img)
                self.logger.info(f"Input image copied to: {unsigned_img}")

        # Load private key
        private_key = self.load_private_key(args.key_file)

        # Compute header and signature
        header, sig_block = self.compute_header_and_signature(unsigned_img, private_key)

        # Write signed image (final output)
        try:
            with signed_img.open('wb') as out_f:
                out_f.write(header)
                with unsigned_img.open('rb') as img_f:
                    while chunk := img_f.read(self.chunk_size):
                        out_f.write(chunk)
                out_f.write(sig_block)

            self.logger.info(f"Signed image written to: {signed_img}")
        except IOError as e:
            raise RuntimeError(f"Failed to write signed image: {e}")

        # Append certificate chain to signed image
        self.append_cert_chain(signed_img, args.cert_file)

        self.logger.info(f"Unsigned SquashFS image: {unsigned_img}")
        self.logger.info(f"Final signed image: {signed_img}")


def setup_logging(verbose: bool = False) -> None:
    """Setup logging configuration"""
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format='%(levelname)s: %(message)s',
        handlers=[logging.StreamHandler()]
    )


# Update argument parser description to reflect new behavior
def create_argument_parser() -> argparse.ArgumentParser:
    """Create and configure argument parser"""
    parser = argparse.ArgumentParser(
        description="Pack, sign, and optionally append certificate chain to an image. "
                   "Creates unsigned SquashFS image with _unsigned postfix and final signed image at -o path.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Create and sign new image from directory
  # Create and sign new image from directory
  # Creates: output_unsigned.img (SquashFS) and output.img (signed)
  %(prog)s -rf /path/to/root -o output.img -ptm /usr/bin/mksquashfs -kf key.pem -v 1.0.0

  # Sign existing image
  # Creates: signed_unsigned.img (SquashFS copy) and signed.img (signed)
  %(prog)s -si existing.img -o signed.img -kf key.pem -cf cert.pem
        """
    )

    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('-rf', '--root-folder', type=Path,
        help="Source directory for creating a new SquashFS image. "
             "A version file will be created at etc/app_version")
    group.add_argument('-si', '--sign-image', type=Path,
        help="Existing SquashFS file to sign only")

    parser.add_argument('-o', '--output-image', required=True, type=Path,
        help="Final signed image output path. Unsigned SquashFS image will be created "
             f"with '{Config.UNSIGNED_IMAGE_POSTFIX}' postfix")
    parser.add_argument('-ptm', '--mksquashfs-path', type=Path,
        help="Path to the mksquashfs binary (required when creating a new image)")
    parser.add_argument('-kf', '--key-file', required=True, type=Path,
        help="Private RSA key file in PEM or DER format")
    parser.add_argument('-cf', '--cert-file', type=Path,
        help="Certificate chain file to append (PEM bundle; can include intermediate and leaf certificates)")
    parser.add_argument('-v', '--version', type=str,
        help="Version string for the new image (only used with --root-folder)")
    parser.add_argument('--verbose', action='store_true',
        help="Enable verbose output")

    return parser


def main() -> None:
    """Main entry point"""
    parser = create_argument_parser()
    args = parser.parse_args()

    setup_logging(args.verbose)
    # Use Crypto or Cryptodome namespace because in Debian Bookworm
    # the Crypto namespace is not available
    # This is a workaround for the Debian Bookworm namespace issue
    logging.info(f"Using {NAMESPACE} namespace for cryptographic operations")

    try:
        signer = ImageSigner()
        signer.create_signed_image(args)
    except (ValueError, RuntimeError) as e:
        logging.error(str(e))
        raise SystemExit(1)
    except KeyboardInterrupt:
        logging.info("Operation cancelled by user")
        raise SystemExit(130)
    except Exception as e:
        logging.error(f"Unexpected error: {e}")
        if args.verbose:
            logging.exception("Full traceback:")
        raise SystemExit(1)


if __name__ == '__main__':
    main()
