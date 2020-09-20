# Linux-Mini
Customize a mini Linux by cropping the initrd and kernel

## Background

Linux-Mini is the final course design of 《Linux Basic》 of SeedClass HUST, which is aiming at customize our own Linux with:

- initrd < 4MB
- kernel < 24MB
- Functions:
  - **RUN IN INITRAMFS, which means YOU CAN DO ANYTHING **
  - could boot with U Disk
  - could mount host disks
  - could visit internet and support ssh

I manually pack up the initrd with the necessary bin files, libs and modules. And compile Linux kernel 5.3.9 with much useless modules cut.

## Usage

```bash
# Clone repo and Enter the directory
git clone https://github.com/QGrain/Linux-Mini.git
cd ./Linux-Mini

# Execute gen-x.x.sh
./gen-x.x.sh

# Then reboot to see the changes
```

## Tips

- Remember to clone all the files in the repo, as the `autocopy.sh`, `autopack.sh` and `my-utils.sh` is required.
- TO SEEDCLASS JUNIORS: do not copy the codes entirely.