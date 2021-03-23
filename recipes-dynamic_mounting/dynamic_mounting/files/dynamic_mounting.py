#!/usr/bin/python3
# -*- coding: iso-8859-15 -*-
import configparser as cp
import subprocess as sp
from os import path
from pathlib import Path

class DynamicApplicationMounting(object):
    def __init__(self, img_path: str):
        """
        Mounts dynamic images as a loopback device
        @param: img_path: Absolute path to the image
        """
        self.mount_cmd = "mount -t {type} {basePath} -o {options} {path}"
        self.img_path = img_path


    def set_lower_directory(self, parent_overlay):
        """
        Set the lower directory, stacking is possbible
        @param: parent_overlay: Can be a DynamicApplicationMounting object or a absolut description of former overlays
        """
        if isinstance(parent_overlay, DynamicApplicationMounting):
            self.lower_dir = parent_overlay.lower_dir + ":" + self.lower_dir
        else:
            self.lower_dir = parent_overlay

    def set_upper_directory(self, upper: str):
        """
        Set here the upper directory (only needed for writebale applicaion images)
        @param: upper: The absolut path to the upper directory
        """
        self.upper_dir = upper

    def set_work_directory(self, work: str):
        """
        Set here the work directory (only needed for writebale application images)
        @param: work: Must be on the same device as the upper directory.
        """
        self.work_dir = work

    def mount(self, img_type: str, img_options: str, dest_path: str):
        """
        Mount the image onto the device
        @param: img_type: Define the image for the mount -t parameter (optional; string can be empty)
                img_options: Define the options for mounting your application image (optional; string can be empty)
                dest_path: The destination folder for access in the root directory

        """
        handle_loop_device = sp.Popen("losetup -f", shell=True, stdout=sp.PIPE)
        handle_loop_device.wait()
        if handle_loop_device.returncode != 0:
            raise(Exception("Error while determine the next free loopack device"))

        loop_device = handle_loop_device.stdout.read().decode("ASCII").rstrip()
        handle_loop_device = sp.Popen("losetup {loop_dev} {img_path}".format(loop_dev=loop_device, img_path=self.img_path), shell=True, stdout=sp.PIPE)
        handle_loop_device.wait()
        if handle_loop_device.returncode != 0:
            raise(Exception("Error while mounting the loopback device"))

        handle = sp.Popen(self.mount_cmd.format(type=img_type, basePath=loop_device, options=img_options, path=dest_path), shell=True, stdout=sp.PIPE)
        handle.wait()
        if handle.returncode != 0:
            raise(Exception("Mounting loopback device on filesystem: {}".format(self.mount_cmd.format(type=img_type, basePath=loop_device, options=img_options, path=dest_path))))

    def mount_overlay(self, read_only: bool, merge_path: str):
        """
        Mount the loopback device as an overlay
        @param: read_only: The overlay do not define work and upper directory
                merge_path: The resuloting destination path of the overlay mount
        """
        if read_only:
            if hasattr(self, 'lower_dir'):
                options = f"lowerdir={self.lower_dir}"
                mount_overlay_cmd = self.mount_cmd.format(type="overlay", basePath="overlay", options=options, path=merge_path)
            else:
                raise(Exception("Lower directory is not defined"))
        else:
            if hasattr(self, 'lower_dir') and hasattr(self, 'upper_dir') and hasattr(self, 'work_dir'):
                options = f"lowerdir={self.lower_dir},upperdir={self.upper_dir},workdir={self.work_dir}"
                mount_overlay_cmd = self.mount_cmd.format(type="overlay", basePath="overlay", options=options, path=merge_path)
            else:
                raise(Exception("work, upper or lower directory not defined"))

        handle = sp.Popen(mount_overlay_cmd, shell=True, stdout=sp.PIPE)
        handle.wait()
        if handle.returncode != 0:
            raise(Exception(f"Mounting overlay failed: {mount_overlay_cmd}"))

class SelectApplication(object):
    def __init__(self):
        self.app_a = DynamicApplicationMounting("/rw_fs/root/application/app_a.squashfs")
        self.app_b = DynamicApplicationMounting("/rw_fs/root/application/app_b.squashfs")

    def mount(self):
        handler = sp.Popen("fw_printenv -n application", shell=True, stdout=sp.PIPE)
        handler.wait()
        if handler.returncode != 0:
            raise(Exception("Could not read u-boot variable \"application\""))

        application = handler.stdout.read().decode("ASCII").rstrip()
        if application == "A":
            self.mounpoint = self.app_a
        elif application == "B":
            self.mounpoint = self.app_b
        else:
            raise(Exception("fw_printenv do not contain the valid values \"A\" or \"B\""))

        self.mounpoint.mount("squashfs", "defaults", "/rw_fs/root/application/current")

    def mount_overlay_application(self,folder_filesystem: str):
        self.mounpoint.set_lower_directory(folder_filesystem + ":/rw_fs/root/application/current" + folder_filesystem)
        self.mounpoint.mount_overlay(True, folder_filesystem)

    def mount_overlay_persistent_mem(self, lowerdir: str, upperdir: str, workdir: str, mergedir: str):
        if path.exists(lowerdir) == False:
            Path(lowerdir).mkdir(partents=True, exist_ok=True)
        if path.exists(upperdir) == False:
            Path(upperdir).mkdir(parents=True, exist_ok=True)
        if path.exists(workdir) == False:
            Path(workdir).mkdir(parents=True, exist_ok=True)
        mount_cmd = f"mount -t overlay overlay -o defaults,lowerdir={lowerdir},upperdir={upperdir},workdir={workdir} {mergedir}"
        handle = sp.Popen(mount_cmd, shell=True)
        handle.wait()
        if handle.returncode != 0:
            print(f"Error while mounting overlay: {mount_cmd}")


class ReadConfigFileU(object):
    def __init__(self, PathToIni: str = "/rw_fs/root/application/current/overlay.ini"):
        self.select = SelectApplication()
        self.select.mount()
        self.cp = cp.ConfigParser()
        try:
            self.cp.read(PathToIni)
        except Exception as err:
            print("Error while parsing overly.ini: ".format(err))

    def run_config(self):

        if "ApplicationFolder" not in self.cp._sections.keys():
            print("No ApplicationFolder header in overlay.ini")
            exit(1)
        for key, value in self.cp._sections.items():
            if key == "ApplicationFolder":
                for key, value in value.items():
                    self.select.mount_overlay_application(value)
        for key, value in self.cp._sections.items():
            if key.startswith("PersistentMemory."):
                try:
                    self.select.mount_overlay_persistent_mem(value["lowerdir"], value["upperdir"], value["workdir"], value["mergedir"])
                except:
                    print("Not correct values for persistent memory: {}".format(key))
                    exit(1)

dyn_mount = ReadConfigFileU()
dyn_mount.run_config()

