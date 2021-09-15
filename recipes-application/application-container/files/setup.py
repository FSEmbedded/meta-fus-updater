import setuptools


setuptools.setup(
    name="createSignedPackage",
    version="1.0.0",
    author="Götz Grimmer",
    author_email="Grimmer@fs-net.de",
    description="The F&S application packager",
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: POSIX :: Linux",
    ],
    install_requires=[
        'pycryptodome',
    ],
    packages=[
        'createSignedPackage',
    ],
    entry_points = {
        'console_scripts': ['package_app=createSignedPackage.createSignedPackage:main']
    },
    python_requires='>=3.6'
)
