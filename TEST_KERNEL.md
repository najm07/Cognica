# Testing Cognica OS Kernel

## Quick Test

### Option 1: Direct GUI (Windows 11 with WSLg)
```powershell
wsl bash -c "cd /mnt/c/Users/mehdi/source/repos/Cognica && qemu-system-x86_64 -cdrom build/cognica-os.iso -m 128M"
```
A QEMU window should open showing your kernel booting.

### Option 2: VNC Server (Works on all Windows versions)
```powershell
# Start QEMU with VNC
wsl bash -c "cd /mnt/c/Users/mehdi/source/repos/Cognica && qemu-system-x86_64 -cdrom build/cognica-os.iso -m 128M -vnc :1 -daemonize"

# Then connect with a VNC viewer:
# - Install TightVNC Viewer or RealVNC Viewer
# - Connect to: localhost:1
```

### Option 3: Use the Test Script
```powershell
wsl bash -c "cd /mnt/c/Users/mehdi/source/repos/Cognica && ./test-kernel.sh"
```

## What You Should See

When the kernel boots, you should see:
- "Welcome to Cognica OS Kernel!"
- Multiboot magic number confirmation
- Memory information (if available)
- Kernel status and version
- System information

## Stopping QEMU

```powershell
  wsl bash -c "pkill -f qemu-system-x86_64"
```

## Troubleshooting

### No GUI Window Appears
- Use VNC method (Option 2)
- Or install WSLg: `wsl --update` (Windows 11)

### VNC Connection Issues
- Make sure QEMU is running: `wsl bash -c "ps aux | grep qemu"`
- Try a different VNC port: Change `:1` to `:2` in the command
- Check Windows Firewall settings

### Kernel Doesn't Boot
- Verify ISO exists: `wsl bash -c "ls -lh /mnt/c/Users/mehdi/source/repos/Cognica/build/cognica-os.iso"`
- Rebuild: `wsl bash -c "cd /mnt/c/Users/mehdi/source/repos/Cognica && make clean && make iso"`

