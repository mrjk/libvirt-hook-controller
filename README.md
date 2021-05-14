# Libvirt Hook Controller



## 

If you want to quickly recreate symlinks, you can run:
```
for i in /etc/libvirt/hooks/{daemon,libxl,lxc,network,qemu} ; do ln -rs $PWD/scripts/libvirt_hook_controller.sh  $i ; done
```
