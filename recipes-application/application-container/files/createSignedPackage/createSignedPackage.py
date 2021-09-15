def main():
    import argparse
    import subprocess as sp
    from os.path import join, getsize, exists
    from os import remove, stat, getuid
    import binascii
    from pathlib import Path
    import datetime

    from Crypto.Hash import SHA256
    from Crypto.Signature import pss
    from Crypto.PublicKey import RSA

    parser = argparse.ArgumentParser(description="Create an application image and sign it")
    parser.add_argument("-o", "--image_output", required=True, type=str, help="ouput path for placing image")
    parser.add_argument("-rf", "--root_folder", required=True, type=str, help="input folder ")
    parser.add_argument("-ptm","--path_to_mksquashfs", required=True, type=str, help="custom mksquashfs")
    parser.add_argument("-kf","--key_file", required=False, type=str, help="path to the key")
    parser.add_argument("-v", "--version", required=True, type=int, help="type the release date here YYYYMMDD")

    result = parser.parse_args()

    img_file = Path(result.image_output + "_img")
    if img_file.exists():
        remove(result.image_output + "_img")

    path_to_version = join(result.root_folder, "etc", "app_version")
    Path(join(result.root_folder, "etc")).mkdir(parents=False, exist_ok=True)

    with open(path_to_version, "w") as file:
            file.write(str(result.version))
    try:
            remove(result.image_output)
    except FileNotFoundError:
            pass

    handler = sp.Popen(
            result.path_to_mksquashfs + " " + result.root_folder + " " +  result.image_output + "_img",
            shell=True,
            stdout=sp.PIPE)

    handler.wait()
    if handler.returncode != 0:
        raise(Exception("Error while create squashed filesystem: {}".format(handler.stdout.read().decode('ascii'))))

    result = parser.parse_args()

    ### Header for application update
    # |Application-Image-Size [8 Bytes]| Version of Header [4 Bytes]| CRC32 Checksumme |
    # | 00 00 00 00 00 00 00 00 | 00 00 00 00 | 00 00 00 00


    ### create signature section
    if "key_file" in vars(result):
        with open(result.key_file, "rb") as f:
            priv_key = f.read()

	    # create header
        print("Header version 1")
        print("Size of image", getsize(result.image_output + "_img"))

        header = getsize(result.image_output + "_img").to_bytes(8, byteorder="big", signed=False)
        header += int(1).to_bytes(4, byteorder="big", signed=False)
        header += binascii.crc32(header).to_bytes(4, byteorder="big", signed=False)
        print("Header: ", header)
        print(str(datetime.datetime.utcnow().isoformat()).encode('ascii'))

        signing_utc_iso = str(datetime.datetime.utcnow().isoformat()).encode('ascii')

        key = RSA.import_key(priv_key)
        prehash = SHA256.new()

        with open(result.image_output, "wb") as fo:
            fo.write(header)

            with open(result.image_output + "_img", "rb") as fi:
                while True:
                    file_data = fi.read(512)
                    if len(file_data) == 0:
                        break
                    fo.write(file_data)
                    prehash.update(file_data)

            prehash.update(signing_utc_iso)
            fo.write(signing_utc_iso)
            fo.write(pss.new(key).sign(prehash))
