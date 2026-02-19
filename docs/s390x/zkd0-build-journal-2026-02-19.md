# zkd0 s390x Build Journal

- Date: 2026-02-19
- Workspace: /Users/kaitlyndavis/dev/github.com/k8ika0s/cilium-s390x
- Branch: k8ika0s/s390x-local-pr-stack
- HEAD: f10ddf33b3aac9ef27d117c7bd14f484b10ab373

## Session Start
### Remote Host Identity
```text
zkd01.fyre.ibm.com
Linux zkd01.fyre.ibm.com 5.14.0-570.62.1.el9_6.s390x #1 SMP Mon Nov 3 10:39:25 EST 2025 s390x s390x s390x GNU/Linux
s390x
Architecture:                            s390x
CPU op-mode(s):                          32-bit, 64-bit
Byte Order:                              Big Endian
CPU(s):                                  8
On-line CPU(s) list:                     0-7
Vendor ID:                               IBM/S390
Machine type:                            3906
Thread(s) per core:                      1
Core(s) per socket:                      1
Socket(s) per book:                      1
Book(s) per drawer:                      1
Drawer(s):                               8
CPU dynamic MHz:                         5208
CPU static MHz:                          5208
BogoMIPS:                                3111.00
Dispatching mode:                        horizontal
Flags:                                   esan3 zarch stfle msa ldisp eimm dfp edat etf3eh highgprs te vx vxd vxe gs
Hypervisor:                              KVM/Linux
Hypervisor vendor:                       KVM
Virtualization type:                     full
```

### Remote Prerequisites
```text
PWD: /root
PATH: /root/.cargo/bin:/root/.local/bin:/root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
git       /usr/bin/git
go        /usr/bin/go
gcc       /usr/bin/gcc
clang     llc       make      /usr/bin/make
docker    /root/bin/docker
podman    /usr/bin/podman
nerdctl   rsync     /usr/bin/rsync
tar       /usr/bin/tar
bpftool   /usr/sbin/bpftool
llvm-strip
go version go1.25.5 (Red Hat 1.25.5-2.el9_7) linux/s390x
gcc (GCC) 11.5.0 20240719 (Red Hat 11.5.0-11)
GNU Make 4.3
```

### Sync Attempt #1 (Failure)
```text
time rsync -az --delete --stats /Users/kaitlyndavis/dev/github.com/k8ika0s/cilium-s390x/ zkd0:~/work/cilium-s390x/
rsync: mkdir '/root/work/cilium-s390x' failed: No such file or directory
Fix: mkdir -p ~/work/cilium-s390x on remote
```

### Sync Attempt #2 (Aborted)
```text
Initial full-tree rsync stalled for iterative workflow (large tree, long no-progress window).
Action: aborted and moved to targeted rsync scope for build-critical paths.
```

### Sync Attempt #3 (Targeted Success)
```text
time rsync -az --delete --stats --exclude '.git' --exclude 'Documentation' --exclude 'test' --exclude '.github' --exclude '.vscode' ...
Number of files: 28714
Number of files transferred: 23564
Total transferred file size: 242330221 B
Elapsed: ~1m26s
Result: success

### Build Attempt #1 (Native Go Build/Test)
```text
pwd: /root/work/cilium-s390x
go version go1.25.5 (Red Hat 1.25.5-2.el9_7) linux/s390x
linux
s390x
-- go build selected binaries
```

### Build Attempt #2 (Disable VCS Stamping)
```text
GOFLAGS=-buildvcs=false
-- go build selected binaries
-- go test selected packages
ok  	github.com/cilium/cilium/pkg/byteorder	0.026s
ok  	github.com/cilium/cilium/pkg/container/bitlpm	0.164s
ok  	github.com/cilium/cilium/pkg/maglev	1.468s
ok  	github.com/cilium/cilium/pkg/murmur3	0.067s
```

### Build Attempt #3 (make build-container)
```text
for i in cilium-dbg daemon cilium-health bugtool hubble tools/mount tools/sysctlfix plugins/cilium-cni; do make  -C $i all; done
make[1]: Entering directory '/root/work/cilium-s390x/cilium-dbg'
CGO_ENABLED=0 GOARCH=s390x go build -mod=vendor -ldflags '-X "github.com/cilium/cilium/pkg/version.ciliumVersion=1.20.0-dev " -s -w -X "github.com/cilium/cilium/pkg/envoy.requiredEnvoyVersionSHA=14da6b9c8a54244f0a67cd90a0deb83e5f110a4a" ' -tags=osusergo  -o cilium-dbg
make[1]: Leaving directory '/root/work/cilium-s390x/cilium-dbg'
make[1]: Entering directory '/root/work/cilium-s390x/daemon'
CGO_ENABLED=0 GOARCH=s390x go build -mod=vendor -ldflags '-X "github.com/cilium/cilium/pkg/version.ciliumVersion=1.20.0-dev " -s -w -X "github.com/cilium/cilium/pkg/envoy.requiredEnvoyVersionSHA=14da6b9c8a54244f0a67cd90a0deb83e5f110a4a" ' -tags=osusergo  -o cilium-agent
make[1]: Leaving directory '/root/work/cilium-s390x/daemon'
make[1]: Entering directory '/root/work/cilium-s390x/cilium-health'
CGO_ENABLED=0 GOARCH=s390x go build -mod=vendor -ldflags '-X "github.com/cilium/cilium/pkg/version.ciliumVersion=1.20.0-dev " -s -w -X "github.com/cilium/cilium/pkg/envoy.requiredEnvoyVersionSHA=14da6b9c8a54244f0a67cd90a0deb83e5f110a4a" ' -tags=osusergo  -o cilium-health
make[2]: Entering directory '/root/work/cilium-s390x/cilium-health/responder'
CGO_ENABLED=0 GOARCH=s390x go build -mod=vendor -ldflags '-X "github.com/cilium/cilium/pkg/version.ciliumVersion=1.20.0-dev " -s -w -X "github.com/cilium/cilium/pkg/envoy.requiredEnvoyVersionSHA=14da6b9c8a54244f0a67cd90a0deb83e5f110a4a" ' -tags=osusergo  -o cilium-health-responder
make[2]: Leaving directory '/root/work/cilium-s390x/cilium-health/responder'
make[1]: Leaving directory '/root/work/cilium-s390x/cilium-health'
make[1]: Entering directory '/root/work/cilium-s390x/bugtool'
CGO_ENABLED=0 GOARCH=s390x go build -mod=vendor -ldflags '-X "github.com/cilium/cilium/pkg/version.ciliumVersion=1.20.0-dev " -s -w -X "github.com/cilium/cilium/pkg/envoy.requiredEnvoyVersionSHA=14da6b9c8a54244f0a67cd90a0deb83e5f110a4a" ' -tags=osusergo  -o cilium-bugtool
make[1]: Leaving directory '/root/work/cilium-s390x/bugtool'
make[1]: Entering directory '/root/work/cilium-s390x/hubble'
CGO_ENABLED=0 GOARCH=s390x go build -mod=vendor -ldflags '-X "github.com/cilium/cilium/pkg/version.ciliumVersion=1.20.0-dev " -s -w -X "github.com/cilium/cilium/pkg/envoy.requiredEnvoyVersionSHA=14da6b9c8a54244f0a67cd90a0deb83e5f110a4a" -X "github.com/cilium/cilium/hubble/pkg.GitBranch=" -X "github.com/cilium/cilium/hubble/pkg.GitHash=" -X "github.com/cilium/cilium/hubble/pkg.Version=v1.20.0-dev" ' -tags=osusergo  -o ./hubble .
make[1]: Leaving directory '/root/work/cilium-s390x/hubble'
make[1]: Entering directory '/root/work/cilium-s390x/tools/mount'
CGO_ENABLED=0 GOARCH=s390x go build -mod=vendor -ldflags '-X "github.com/cilium/cilium/pkg/version.ciliumVersion=1.20.0-dev " -s -w -X "github.com/cilium/cilium/pkg/envoy.requiredEnvoyVersionSHA=14da6b9c8a54244f0a67cd90a0deb83e5f110a4a" ' -tags=osusergo  -o cilium-mount
make[1]: Leaving directory '/root/work/cilium-s390x/tools/mount'
make[1]: Entering directory '/root/work/cilium-s390x/tools/sysctlfix'
CGO_ENABLED=0 GOARCH=s390x go build -mod=vendor -ldflags '-X "github.com/cilium/cilium/pkg/version.ciliumVersion=1.20.0-dev " -s -w -X "github.com/cilium/cilium/pkg/envoy.requiredEnvoyVersionSHA=14da6b9c8a54244f0a67cd90a0deb83e5f110a4a" ' -tags=osusergo  -o cilium-sysctlfix
make[1]: Leaving directory '/root/work/cilium-s390x/tools/sysctlfix'
make[1]: Entering directory '/root/work/cilium-s390x/plugins/cilium-cni'
CGO_ENABLED=0 GOARCH=s390x go build -mod=vendor -ldflags '-X "github.com/cilium/cilium/pkg/version.ciliumVersion=1.20.0-dev " -s -w -X "github.com/cilium/cilium/pkg/envoy.requiredEnvoyVersionSHA=14da6b9c8a54244f0a67cd90a0deb83e5f110a4a" ' -tags=osusergo  -o cilium-cni
make[1]: Leaving directory '/root/work/cilium-s390x/plugins/cilium-cni'
```

### Remediation #1 (Git Safe Directory + Ownership Check)
```text
501:20 /root/work/cilium-s390x
501:20 /root/work/cilium-s390x/Makefile
/root/pandas-s390x
/root/pandas-0+local
/root/work/cilium-s390x
```

### Remediation #2 (Normalize Ownership)
```text
0:0 /root/work/cilium-s390x
0:0 /root/work/cilium-s390x/Makefile
git rev-parse failed (expected with no .git)
```

### Build Attempt #4 (BPF Datapath Build)
```text
make: Entering directory '/root/work/cilium-s390x/bpf'
clang -DSKIP_DEBUG=1 -DENABLE_IPV4=1 -DENABLE_IPV6=1 -DENABLE_ROUTING=1 -DPOLICY_VERDICT_NOTIFY=1 -DENABLE_IDENTITY_MARK=1 -DMONITOR_AGGREGATION=3 -DCT_REPORT_FLAGS=0x0002 -DENABLE_HOST_FIREWALL=1 -DENABLE_SRV6=1 -DENABLE_L7_LB=1 -DENABLE_MASQUERADE_IPV4=1 -DENABLE_IP_MASQ_AGENT_IPV4=1 -DENABLE_MASQUERADE_IPV6=1 -DENABLE_IP_MASQ_AGENT_IPV6=1 -DENABLE_NODEPORT=1 -DENABLE_NODEPORT_ACCELERATION=1 -DENABLE_DSR_ICMP_ERRORS=1 -DENABLE_DSR=1 -DENABLE_DSR_BYUSER=1 -DENABLE_IPV4_FRAGMENTS=1 -DENABLE_BANDWIDTH_MANAGER=1 -DENABLE_EGRESS_GATEWAY=1 -DENABLE_VTEP=1 -DENABLE_TPROXY=1 -DENABLE_HOST_ROUTING=1 -DENABLE_CLUSTER_AWARE_ADDRESSING=1 -DENABLE_INTER_CLUSTER_SNAT=1 -DENCAP_IFINDEX=1 -DTUNNEL_MODE=1 -I/root/work/cilium-s390x/bpf -I/root/work/cilium-s390x/bpf/include -O2 -g --target=bpf -std=gnu99 -nostdinc -ftrap-function=__undefined_trap -Wall -Wextra -Werror -Wshadow -Wno-address-of-packed-member -Wno-unknown-warning-option -Wno-gnu-variable-sized-type-not-at-end -Wimplicit-int-conversion -Wenum-conversion -Wimplicit-fallthrough -mcpu=v3 -c bpf_lxc.c -o bpf_lxc.o
make: Leaving directory '/root/work/cilium-s390x/bpf'
```

### Remediation #3 (Install LLVM/Clang on zkd0)
```text
Updating Subscription Management repositories.
Red Hat Enterprise Linux 9 for IBM z Systems -   46 kB/s | 4.5 kB     00:00    
Red Hat Enterprise Linux 9 for IBM z Systems -   38 kB/s | 4.1 kB     00:00    
Dependencies resolved.
=======================================================================================================
 Package                          Arch   Version                 Repository                        Size
=======================================================================================================
Installing:
 clang                            s390x  20.1.8-3.el9            rhel-9-for-s390x-appstream-rpms  156 k
 llvm                             s390x  20.1.8-3.el9            rhel-9-for-s390x-appstream-rpms   24 M
 llvm-devel                       s390x  20.1.8-3.el9            rhel-9-for-s390x-appstream-rpms  5.5 M
Upgrading:
 annobin                          s390x  12.98-1.el9             rhel-9-for-s390x-appstream-rpms  1.1 M
 bpftool                          s390x  7.5.0-803.el9           rhel-9-for-s390x-appstream-rpms  307 k
 llvm-libs                        s390x  20.1.8-3.el9            rhel-9-for-s390x-appstream-rpms   31 M
 mesa-dri-drivers                 s390x  25.0.7-4.el9_7          rhel-9-for-s390x-appstream-rpms  3.4 M
     replacing  mesa-libglapi.s390x 24.2.8-2.el9_6
 mesa-filesystem                  s390x  25.0.7-4.el9_7          rhel-9-for-s390x-appstream-rpms   17 k
 mesa-libEGL                      s390x  25.0.7-4.el9_7          rhel-9-for-s390x-appstream-rpms  136 k
 mesa-libGL                       s390x  25.0.7-4.el9_7          rhel-9-for-s390x-appstream-rpms  171 k
 mesa-libgbm                      s390x  25.0.7-4.el9_7          rhel-9-for-s390x-appstream-rpms   22 k
Installing dependencies:
 clang-libs                       s390x  20.1.8-3.el9            rhel-9-for-s390x-appstream-rpms   31 M
 clang-resource-filesystem        s390x  20.1.8-3.el9            rhel-9-for-s390x-appstream-rpms   15 k
 environment-modules              s390x  5.3.0-2.el9             rhel-9-for-s390x-baseos-rpms     590 k
 gcc-toolset-14-binutils          s390x  2.41-5.el9_7.1          rhel-9-for-s390x-appstream-rpms  6.3 M
 gcc-toolset-14-gcc               s390x  14.2.1-12.el9_7         rhel-9-for-s390x-appstream-rpms   38 M
 gcc-toolset-14-gcc-c++           s390x  14.2.1-12.el9_7         rhel-9-for-s390x-appstream-rpms   12 M
 gcc-toolset-14-libstdc++-devel   s390x  14.2.1-12.el9_7         rhel-9-for-s390x-appstream-rpms  3.7 M
 gcc-toolset-14-runtime           s390x  14.0-2.el9              rhel-9-for-s390x-appstream-rpms   57 k
 libedit-devel                    s390x  3.1-38.20210216cvs.el9  rhel-9-for-s390x-appstream-rpms   51 k
 llvm-filesystem                  s390x  20.1.8-3.el9            rhel-9-for-s390x-appstream-rpms  9.1 k
 llvm-googletest                  s390x  20.1.8-3.el9            rhel-9-for-s390x-appstream-rpms  465 k
 llvm-static                      s390x  20.1.8-3.el9            rhel-9-for-s390x-appstream-rpms   44 M
 llvm-test                        s390x  20.1.8-3.el9            rhel-9-for-s390x-appstream-rpms  744 k
 ncurses-c++-libs                 s390x  6.2-10.20210508.el9_6.2 rhel-9-for-s390x-appstream-rpms   37 k
 ncurses-devel                    s390x  6.2-10.20210508.el9_6.2 rhel-9-for-s390x-appstream-rpms  728 k
 scl-utils                        s390x  1:2.0.3-4.el9           rhel-9-for-s390x-appstream-rpms   41 k
 spirv-tools-libs                 s390x  2025.2-1.el9            rhel-9-for-s390x-appstream-rpms  1.4 M
 tcl                              s390x  1:8.6.10-7.el9          rhel-9-for-s390x-baseos-rpms     1.1 M
Installing weak dependencies:
 compiler-rt                      s390x  20.1.8-3.el9            rhel-9-for-s390x-appstream-rpms  1.7 M
 libomp                           s390x  20.1.8-3.el9            rhel-9-for-s390x-appstream-rpms  636 k
 libomp-devel                     s390x  20.1.8-3.el9            rhel-9-for-s390x-appstream-rpms  281 k

Transaction Summary
=======================================================================================================
Install  24 Packages
Upgrade   8 Packages

Total download size: 208 M
Downloading Packages:
(1/32): libedit-devel-3.1-38.20210216cvs.el9.s3 144 kB/s |  51 kB     00:00    
(2/32): scl-utils-2.0.3-4.el9.s390x.rpm          90 kB/s |  41 kB     00:00    
(3/32): ncurses-c++-libs-6.2-10.20210508.el9_6.  71 kB/s |  37 kB     00:00    
(4/32): ncurses-devel-6.2-10.20210508.el9_6.2.s 6.0 MB/s | 728 kB     00:00    
(5/32): clang-20.1.8-3.el9.s390x.rpm            562 kB/s | 156 kB     00:00    
(6/32): clang-resource-filesystem-20.1.8-3.el9.  57 kB/s |  15 kB     00:00    
(7/32): compiler-rt-20.1.8-3.el9.s390x.rpm      7.9 MB/s | 1.7 MB     00:00    
(8/32): libomp-devel-20.1.8-3.el9.s390x.rpm     954 kB/s | 281 kB     00:00    
(9/32): gcc-toolset-14-gcc-c++-14.2.1-12.el9_7.  17 MB/s |  12 MB     00:00    
(10/32): llvm-filesystem-20.1.8-3.el9.s390x.rpm  23 kB/s | 9.1 kB     00:00    
(11/32): clang-libs-20.1.8-3.el9.s390x.rpm       22 MB/s |  31 MB     00:01    
(12/32): llvm-googletest-20.1.8-3.el9.s390x.rpm 1.2 MB/s | 465 kB     00:00    
(13/32): spirv-tools-libs-2025.2-1.el9.s390x.rp  11 MB/s | 1.4 MB     00:00    
(14/32): gcc-toolset-14-libstdc++-devel-14.2.1-  15 MB/s | 3.7 MB     00:00    
(15/32): gcc-toolset-14-runtime-14.0-2.el9.s390 382 kB/s |  57 kB     00:00    
(16/32): libomp-20.1.8-3.el9.s390x.rpm          3.0 MB/s | 636 kB     00:00    
(17/32): llvm-static-20.1.8-3.el9.s390x.rpm      32 MB/s |  44 MB     00:01    
(18/32): gcc-toolset-14-gcc-14.2.1-12.el9_7.s39  23 MB/s |  38 MB     00:01    
(19/32): llvm-devel-20.1.8-3.el9.s390x.rpm      5.4 MB/s | 5.5 MB     00:01    
(20/32): llvm-test-20.1.8-3.el9.s390x.rpm       1.6 MB/s | 744 kB     00:00    
(21/32): llvm-20.1.8-3.el9.s390x.rpm             15 MB/s |  24 MB     00:01    
(22/32): tcl-8.6.10-7.el9.s390x.rpm             3.0 MB/s | 1.1 MB     00:00    
(23/32): gcc-toolset-14-binutils-2.41-5.el9_7.1  11 MB/s | 6.3 MB     00:00    
(24/32): environment-modules-5.3.0-2.el9.s390x. 1.9 MB/s | 590 kB     00:00    
(25/32): annobin-12.98-1.el9.s390x.rpm          5.1 MB/s | 1.1 MB     00:00    
(26/32): bpftool-7.5.0-803.el9.s390x.rpm        3.2 MB/s | 307 kB     00:00    
(27/32): mesa-filesystem-25.0.7-4.el9_7.s390x.r  98 kB/s |  17 kB     00:00    
(28/32): mesa-dri-drivers-25.0.7-4.el9_7.s390x. 9.3 MB/s | 3.4 MB     00:00    
(29/32): mesa-libEGL-25.0.7-4.el9_7.s390x.rpm   705 kB/s | 136 kB     00:00    
(30/32): mesa-libGL-25.0.7-4.el9_7.s390x.rpm    1.6 MB/s | 171 kB     00:00    
(31/32): llvm-libs-20.1.8-3.el9.s390x.rpm        40 MB/s |  31 MB     00:00    
(32/32): mesa-libgbm-25.0.7-4.el9_7.s390x.rpm    66 kB/s |  22 kB     00:00    
--------------------------------------------------------------------------------
Total                                            38 MB/s | 208 MB     00:05     
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                        1/1 
  Installing       : llvm-filesystem-20.1.8-3.el9.s390x                    1/41 
  Upgrading        : llvm-libs-20.1.8-3.el9.s390x                          2/41 
  Installing       : clang-resource-filesystem-20.1.8-3.el9.s390x          3/41 
  Installing       : libomp-20.1.8-3.el9.s390x                             4/41 
  Installing       : llvm-20.1.8-3.el9.s390x                               5/41 
  Installing       : llvm-test-20.1.8-3.el9.s390x                          6/41 
  Installing       : libomp-devel-20.1.8-3.el9.s390x                       7/41 
  Installing       : compiler-rt-20.1.8-3.el9.s390x                        8/41 
  Installing       : llvm-googletest-20.1.8-3.el9.s390x                    9/41 
  Installing       : llvm-static-20.1.8-3.el9.s390x                       10/41 
  Upgrading        : mesa-filesystem-25.0.7-4.el9_7.s390x                 11/41 
  Installing       : tcl-1:8.6.10-7.el9.s390x                             12/41 
  Installing       : environment-modules-5.3.0-2.el9.s390x                13/41 
  Running scriptlet: environment-modules-5.3.0-2.el9.s390x                13/41 
  Installing       : scl-utils-1:2.0.3-4.el9.s390x                        14/41 
  Installing       : gcc-toolset-14-runtime-14.0-2.el9.s390x              15/41 
  Running scriptlet: gcc-toolset-14-runtime-14.0-2.el9.s390x              15/41 
  Installing       : gcc-toolset-14-libstdc++-devel-14.2.1-12.el9_7.s39   16/41 
  Installing       : gcc-toolset-14-binutils-2.41-5.el9_7.1.s390x         17/41 
  Running scriptlet: gcc-toolset-14-binutils-2.41-5.el9_7.1.s390x         17/41 
  Installing       : gcc-toolset-14-gcc-14.2.1-12.el9_7.s390x             18/41 
  Installing       : gcc-toolset-14-gcc-c++-14.2.1-12.el9_7.s390x         19/41 
  Installing       : clang-libs-20.1.8-3.el9.s390x                        20/41 
  Installing       : spirv-tools-libs-2025.2-1.el9.s390x                  21/41 
  Upgrading        : mesa-libEGL-25.0.7-4.el9_7.s390x                     22/41 
  Upgrading        : mesa-libgbm-25.0.7-4.el9_7.s390x                     23/41 
  Upgrading        : mesa-dri-drivers-25.0.7-4.el9_7.s390x                24/41 
  Installing       : ncurses-c++-libs-6.2-10.20210508.el9_6.2.s390x       25/41 
  Installing       : ncurses-devel-6.2-10.20210508.el9_6.2.s390x          26/41 
  Installing       : libedit-devel-3.1-38.20210216cvs.el9.s390x           27/41 
  Installing       : llvm-devel-20.1.8-3.el9.s390x                        28/41 
  Running scriptlet: llvm-devel-20.1.8-3.el9.s390x                        28/41 
  Upgrading        : mesa-libGL-25.0.7-4.el9_7.s390x                      29/41 
  Installing       : clang-20.1.8-3.el9.s390x                             30/41 
  Upgrading        : annobin-12.98-1.el9.s390x                            31/41 
  Running scriptlet: annobin-12.98-1.el9.s390x                            31/41 
  Upgrading        : bpftool-7.5.0-803.el9.s390x                          32/41 
  Cleanup          : mesa-libGL-24.2.8-2.el9_6.s390x                      33/41 
  Cleanup          : mesa-libEGL-24.2.8-2.el9_6.s390x                     34/41 
  Cleanup          : mesa-libgbm-24.2.8-2.el9_6.s390x                     35/41 
  Cleanup          : mesa-dri-drivers-24.2.8-2.el9_6.s390x                36/41 
  Cleanup          : bpftool-7.5.0-802.el9_6.s390x                        37/41 
  Cleanup          : annobin-12.92-1.el9.s390x                            38/41 
  Running scriptlet: annobin-12.92-1.el9.s390x                            38/41 
  Cleanup          : mesa-filesystem-24.2.8-2.el9_6.s390x                 39/41 
  Cleanup          : llvm-libs-19.1.7-2.el9.s390x                         40/41 
  Obsoleting       : mesa-libglapi-24.2.8-2.el9_6.s390x                   41/41 
  Running scriptlet: mesa-libglapi-24.2.8-2.el9_6.s390x                   41/41 
  Verifying        : scl-utils-1:2.0.3-4.el9.s390x                         1/41 
  Verifying        : libedit-devel-3.1-38.20210216cvs.el9.s390x            2/41 
  Verifying        : ncurses-c++-libs-6.2-10.20210508.el9_6.2.s390x        3/41 
  Verifying        : ncurses-devel-6.2-10.20210508.el9_6.2.s390x           4/41 
  Verifying        : clang-20.1.8-3.el9.s390x                              5/41 
  Verifying        : clang-libs-20.1.8-3.el9.s390x                         6/41 
  Verifying        : clang-resource-filesystem-20.1.8-3.el9.s390x          7/41 
  Verifying        : compiler-rt-20.1.8-3.el9.s390x                        8/41 
  Verifying        : gcc-toolset-14-gcc-c++-14.2.1-12.el9_7.s390x          9/41 
  Verifying        : libomp-devel-20.1.8-3.el9.s390x                      10/41 
  Verifying        : llvm-filesystem-20.1.8-3.el9.s390x                   11/41 
  Verifying        : llvm-googletest-20.1.8-3.el9.s390x                   12/41 
  Verifying        : llvm-static-20.1.8-3.el9.s390x                       13/41 
  Verifying        : spirv-tools-libs-2025.2-1.el9.s390x                  14/41 
  Verifying        : gcc-toolset-14-gcc-14.2.1-12.el9_7.s390x             15/41 
  Verifying        : gcc-toolset-14-libstdc++-devel-14.2.1-12.el9_7.s39   16/41 
  Verifying        : gcc-toolset-14-runtime-14.0-2.el9.s390x              17/41 
  Verifying        : libomp-20.1.8-3.el9.s390x                            18/41 
  Verifying        : llvm-20.1.8-3.el9.s390x                              19/41 
  Verifying        : llvm-devel-20.1.8-3.el9.s390x                        20/41 
  Verifying        : llvm-test-20.1.8-3.el9.s390x                         21/41 
  Verifying        : gcc-toolset-14-binutils-2.41-5.el9_7.1.s390x         22/41 
  Verifying        : tcl-1:8.6.10-7.el9.s390x                             23/41 
  Verifying        : environment-modules-5.3.0-2.el9.s390x                24/41 
  Verifying        : annobin-12.98-1.el9.s390x                            25/41 
  Verifying        : annobin-12.92-1.el9.s390x                            26/41 
  Verifying        : bpftool-7.5.0-803.el9.s390x                          27/41 
  Verifying        : bpftool-7.5.0-802.el9_6.s390x                        28/41 
  Verifying        : llvm-libs-20.1.8-3.el9.s390x                         29/41 
  Verifying        : llvm-libs-19.1.7-2.el9.s390x                         30/41 
  Verifying        : mesa-dri-drivers-25.0.7-4.el9_7.s390x                31/41 
  Verifying        : mesa-dri-drivers-24.2.8-2.el9_6.s390x                32/41 
  Verifying        : mesa-libglapi-24.2.8-2.el9_6.s390x                   33/41 
  Verifying        : mesa-filesystem-25.0.7-4.el9_7.s390x                 34/41 
  Verifying        : mesa-filesystem-24.2.8-2.el9_6.s390x                 35/41 
  Verifying        : mesa-libEGL-25.0.7-4.el9_7.s390x                     36/41 
  Verifying        : mesa-libEGL-24.2.8-2.el9_6.s390x                     37/41 
  Verifying        : mesa-libGL-25.0.7-4.el9_7.s390x                      38/41 
  Verifying        : mesa-libGL-24.2.8-2.el9_6.s390x                      39/41 
  Verifying        : mesa-libgbm-25.0.7-4.el9_7.s390x                     40/41 
  Verifying        : mesa-libgbm-24.2.8-2.el9_6.s390x                     41/41 
Installed products updated.

Upgraded:
  annobin-12.98-1.el9.s390x              bpftool-7.5.0-803.el9.s390x            
  llvm-libs-20.1.8-3.el9.s390x           mesa-dri-drivers-25.0.7-4.el9_7.s390x  
  mesa-filesystem-25.0.7-4.el9_7.s390x   mesa-libEGL-25.0.7-4.el9_7.s390x       
  mesa-libGL-25.0.7-4.el9_7.s390x        mesa-libgbm-25.0.7-4.el9_7.s390x       
Installed:
  clang-20.1.8-3.el9.s390x                                                      
  clang-libs-20.1.8-3.el9.s390x                                                 
  clang-resource-filesystem-20.1.8-3.el9.s390x                                  
  compiler-rt-20.1.8-3.el9.s390x                                                
  environment-modules-5.3.0-2.el9.s390x                                         
  gcc-toolset-14-binutils-2.41-5.el9_7.1.s390x                                  
  gcc-toolset-14-gcc-14.2.1-12.el9_7.s390x                                      
  gcc-toolset-14-gcc-c++-14.2.1-12.el9_7.s390x                                  
  gcc-toolset-14-libstdc++-devel-14.2.1-12.el9_7.s390x                          
  gcc-toolset-14-runtime-14.0-2.el9.s390x                                       
  libedit-devel-3.1-38.20210216cvs.el9.s390x                                    
  libomp-20.1.8-3.el9.s390x                                                     
  libomp-devel-20.1.8-3.el9.s390x                                               
  llvm-20.1.8-3.el9.s390x                                                       
  llvm-devel-20.1.8-3.el9.s390x                                                 
  llvm-filesystem-20.1.8-3.el9.s390x                                            
  llvm-googletest-20.1.8-3.el9.s390x                                            
  llvm-static-20.1.8-3.el9.s390x                                                
  llvm-test-20.1.8-3.el9.s390x                                                  
  ncurses-c++-libs-6.2-10.20210508.el9_6.2.s390x                                
  ncurses-devel-6.2-10.20210508.el9_6.2.s390x                                   
  scl-utils-1:2.0.3-4.el9.s390x                                                 
  spirv-tools-libs-2025.2-1.el9.s390x                                           
  tcl-1:8.6.10-7.el9.s390x                                                      

Complete!
```

### Build Attempt #5 (BPF Build After LLVM Install)
```text
clang version 20.1.8 (Red Hat, Inc. 20.1.8-3.el9)
LLVM (http://llvm.org/):
make: Entering directory '/root/work/cilium-s390x/bpf'
clang -DSKIP_DEBUG=1 -DENABLE_IPV4=1 -DENABLE_IPV6=1 -DENABLE_ROUTING=1 -DPOLICY_VERDICT_NOTIFY=1 -DENABLE_IDENTITY_MARK=1 -DMONITOR_AGGREGATION=3 -DCT_REPORT_FLAGS=0x0002 -DENABLE_HOST_FIREWALL=1 -DENABLE_SRV6=1 -DENABLE_L7_LB=1 -DENABLE_MASQUERADE_IPV4=1 -DENABLE_IP_MASQ_AGENT_IPV4=1 -DENABLE_MASQUERADE_IPV6=1 -DENABLE_IP_MASQ_AGENT_IPV6=1 -DENABLE_NODEPORT=1 -DENABLE_NODEPORT_ACCELERATION=1 -DENABLE_DSR_ICMP_ERRORS=1 -DENABLE_DSR=1 -DENABLE_DSR_BYUSER=1 -DENABLE_IPV4_FRAGMENTS=1 -DENABLE_BANDWIDTH_MANAGER=1 -DENABLE_EGRESS_GATEWAY=1 -DENABLE_VTEP=1 -DENABLE_TPROXY=1 -DENABLE_HOST_ROUTING=1 -DENABLE_CLUSTER_AWARE_ADDRESSING=1 -DENABLE_INTER_CLUSTER_SNAT=1 -DENCAP_IFINDEX=1 -DTUNNEL_MODE=1 -I/root/work/cilium-s390x/bpf -I/root/work/cilium-s390x/bpf/include -O2 -g --target=bpf -std=gnu99 -nostdinc -ftrap-function=__undefined_trap -Wall -Wextra -Werror -Wshadow -Wno-address-of-packed-member -Wno-unknown-warning-option -Wno-gnu-variable-sized-type-not-at-end -Wimplicit-int-conversion -Wenum-conversion -Wimplicit-fallthrough -mcpu=v3 -c bpf_lxc.c -o bpf_lxc.o
clang -DSKIP_DEBUG=1 -DENABLE_IPV4=1 -DENABLE_IPV6=1 -DENABLE_ROUTING=1 -DPOLICY_VERDICT_NOTIFY=1 -DENABLE_IDENTITY_MARK=1 -DMONITOR_AGGREGATION=3 -DCT_REPORT_FLAGS=0x0002 -DENABLE_HOST_FIREWALL=1 -DENABLE_SRV6=1 -DENABLE_L7_LB=1 -DENABLE_MASQUERADE_IPV4=1 -DENABLE_IP_MASQ_AGENT_IPV4=1 -DENABLE_MASQUERADE_IPV6=1 -DENABLE_IP_MASQ_AGENT_IPV6=1 -DENABLE_NODEPORT=1 -DENABLE_NODEPORT_ACCELERATION=1 -DENABLE_DSR_ICMP_ERRORS=1 -DENABLE_DSR=1 -DENABLE_DSR_BYUSER=1 -DENABLE_IPV4_FRAGMENTS=1 -DENABLE_BANDWIDTH_MANAGER=1 -DENABLE_EGRESS_GATEWAY=1 -DENABLE_VTEP=1 -DENABLE_TPROXY=1 -DENABLE_HOST_ROUTING=1 -DENABLE_CLUSTER_AWARE_ADDRESSING=1 -DENABLE_INTER_CLUSTER_SNAT=1 -DENCAP_IFINDEX=1 -DTUNNEL_MODE=1 -DENABLE_MULTICAST=1 -DLB_SELECTION_PER_SERVICE=1 -DLB_SELECTION_MAGLEV=2 -DLB_SELECTION_RANDOM=1 -DENABLE_IPSEC=1 -I/root/work/cilium-s390x/bpf -I/root/work/cilium-s390x/bpf/include -O2 -g --target=bpf -std=gnu99 -nostdinc -ftrap-function=__undefined_trap -Wall -Wextra -Werror -Wshadow -Wno-address-of-packed-member -Wno-unknown-warning-option -Wno-gnu-variable-sized-type-not-at-end -Wimplicit-int-conversion -Wenum-conversion -Wimplicit-fallthrough -mcpu=v3 -c bpf_overlay.c -o bpf_overlay.o
clang -DSKIP_DEBUG=1 -DENABLE_IPV4=1 -DENABLE_IPV6=1 -DENABLE_ROUTING=1 -DPOLICY_VERDICT_NOTIFY=1 -DENABLE_IDENTITY_MARK=1 -DMONITOR_AGGREGATION=3 -DCT_REPORT_FLAGS=0x0002 -DENABLE_HOST_FIREWALL=1 -DENABLE_SRV6=1 -DENABLE_L7_LB=1 -DENABLE_MASQUERADE_IPV4=1 -DENABLE_IP_MASQ_AGENT_IPV4=1 -DENABLE_MASQUERADE_IPV6=1 -DENABLE_IP_MASQ_AGENT_IPV6=1 -DENABLE_NODEPORT=1 -DENABLE_NODEPORT_ACCELERATION=1 -DENABLE_DSR_ICMP_ERRORS=1 -DENABLE_DSR=1 -DENABLE_DSR_BYUSER=1 -DENABLE_IPV4_FRAGMENTS=1 -DENABLE_BANDWIDTH_MANAGER=1 -DENABLE_EGRESS_GATEWAY=1 -DENABLE_VTEP=1 -DENABLE_TPROXY=1 -DENABLE_HOST_ROUTING=1 -DENABLE_CLUSTER_AWARE_ADDRESSING=1 -DENABLE_INTER_CLUSTER_SNAT=1 -DENABLE_NAT_46X64=1 -DENABLE_NAT_46X64_GATEWAY=1 -DENCAP_IFINDEX=1 -DTUNNEL_MODE=1 -DLB_SELECTION_PER_SERVICE=1 -DLB_SELECTION_MAGLEV=2 -DLB_SELECTION_RANDOM=1 -DENABLE_IPSEC=1 -I/root/work/cilium-s390x/bpf -I/root/work/cilium-s390x/bpf/include -O2 -g --target=bpf -std=gnu99 -nostdinc -ftrap-function=__undefined_trap -Wall -Wextra -Werror -Wshadow -Wno-address-of-packed-member -Wno-unknown-warning-option -Wno-gnu-variable-sized-type-not-at-end -Wimplicit-int-conversion -Wenum-conversion -Wimplicit-fallthrough -mcpu=v3 -c bpf_sock.c -o bpf_sock.o
clang -DSKIP_DEBUG=1 -DENABLE_IPV4=1 -DENABLE_IPV6=1 -DENABLE_ROUTING=1 -DPOLICY_VERDICT_NOTIFY=1 -DENABLE_IDENTITY_MARK=1 -DMONITOR_AGGREGATION=3 -DCT_REPORT_FLAGS=0x0002 -DENABLE_HOST_FIREWALL=1 -DENABLE_SRV6=1 -DENABLE_L7_LB=1 -DENABLE_MASQUERADE_IPV4=1 -DENABLE_IP_MASQ_AGENT_IPV4=1 -DENABLE_MASQUERADE_IPV6=1 -DENABLE_IP_MASQ_AGENT_IPV6=1 -DENABLE_NODEPORT=1 -DENABLE_NODEPORT_ACCELERATION=1 -DENABLE_DSR_ICMP_ERRORS=1 -DENABLE_DSR=1 -DENABLE_DSR_BYUSER=1 -DENABLE_IPV4_FRAGMENTS=1 -DENABLE_BANDWIDTH_MANAGER=1 -DENABLE_EGRESS_GATEWAY=1 -DENABLE_VTEP=1 -DENABLE_TPROXY=1 -DENABLE_HOST_ROUTING=1 -DENABLE_CLUSTER_AWARE_ADDRESSING=1 -DENABLE_INTER_CLUSTER_SNAT=1 -DENCAP_IFINDEX=1 -DTUNNEL_MODE=1 -DENABLE_IPSEC=1 -DENCRYPTION_STRICT_MODE_EGRESS=1 -DENABLE_WIREGUARD=1 -DENCRYPTION_STRICT_MODE_EGRESS=1 -I/root/work/cilium-s390x/bpf -I/root/work/cilium-s390x/bpf/include -O2 -g --target=bpf -std=gnu99 -nostdinc -ftrap-function=__undefined_trap -Wall -Wextra -Werror -Wshadow -Wno-address-of-packed-member -Wno-unknown-warning-option -Wno-gnu-variable-sized-type-not-at-end -Wimplicit-int-conversion -Wenum-conversion -Wimplicit-fallthrough -mcpu=v3 -c bpf_host.c -o bpf_host.o
clang -DSKIP_DEBUG=1 -DENABLE_IPV4=1 -DENABLE_IPV6=1 -DENABLE_ROUTING=1 -DPOLICY_VERDICT_NOTIFY=1 -DENABLE_IDENTITY_MARK=1 -DMONITOR_AGGREGATION=3 -DCT_REPORT_FLAGS=0x0002 -DENABLE_HOST_FIREWALL=1 -DENABLE_SRV6=1 -DENABLE_L7_LB=1 -DENABLE_MASQUERADE_IPV4=1 -DENABLE_IP_MASQ_AGENT_IPV4=1 -DENABLE_MASQUERADE_IPV6=1 -DENABLE_IP_MASQ_AGENT_IPV6=1 -DENABLE_NODEPORT=1 -DENABLE_NODEPORT_ACCELERATION=1 -DENABLE_DSR_ICMP_ERRORS=1 -DENABLE_DSR=1 -DENABLE_DSR_BYUSER=1 -DENABLE_IPV4_FRAGMENTS=1 -DENABLE_BANDWIDTH_MANAGER=1 -DENABLE_EGRESS_GATEWAY=1 -DENABLE_VTEP=1 -DENABLE_TPROXY=1 -DENABLE_HOST_ROUTING=1 -DENABLE_CLUSTER_AWARE_ADDRESSING=1 -DENABLE_INTER_CLUSTER_SNAT=1 -DENCAP_IFINDEX=1 -DTUNNEL_MODE=1 -DENABLE_WIREGUARD=1 -DENABLE_WIREGUARD=1 -I/root/work/cilium-s390x/bpf -I/root/work/cilium-s390x/bpf/include -O2 -g --target=bpf -std=gnu99 -nostdinc -ftrap-function=__undefined_trap -Wall -Wextra -Werror -Wshadow -Wno-address-of-packed-member -Wno-unknown-warning-option -Wno-gnu-variable-sized-type-not-at-end -Wimplicit-int-conversion -Wenum-conversion -Wimplicit-fallthrough -mcpu=v3 -c bpf_wireguard.c -o bpf_wireguard.o
clang -DSKIP_DEBUG=1 -DENABLE_IPV4=1 -DENABLE_IPV6=1 -DENABLE_ROUTING=1 -DPOLICY_VERDICT_NOTIFY=1 -DENABLE_IDENTITY_MARK=1 -DMONITOR_AGGREGATION=3 -DCT_REPORT_FLAGS=0x0002 -DENABLE_HOST_FIREWALL=1 -DENABLE_SRV6=1 -DENABLE_L7_LB=1 -DENABLE_MASQUERADE_IPV4=1 -DENABLE_IP_MASQ_AGENT_IPV4=1 -DENABLE_MASQUERADE_IPV6=1 -DENABLE_IP_MASQ_AGENT_IPV6=1 -DENABLE_NODEPORT=1 -DENABLE_NODEPORT_ACCELERATION=1 -DENABLE_DSR_ICMP_ERRORS=1 -DENABLE_DSR=1 -DENABLE_DSR_BYUSER=1 -DENABLE_IPV4_FRAGMENTS=1 -DENABLE_BANDWIDTH_MANAGER=1 -DENABLE_EGRESS_GATEWAY=1 -DENABLE_VTEP=1 -DENABLE_TPROXY=1 -DENABLE_HOST_ROUTING=1 -DENABLE_CLUSTER_AWARE_ADDRESSING=1 -DENABLE_INTER_CLUSTER_SNAT=1 -DLB_SELECTION_PER_SERVICE=1 -DLB_SELECTION_MAGLEV=2 -DLB_SELECTION_RANDOM=1 -I/root/work/cilium-s390x/bpf -I/root/work/cilium-s390x/bpf/include -O2 -g --target=bpf -std=gnu99 -nostdinc -ftrap-function=__undefined_trap -Wall -Wextra -Werror -Wshadow -Wno-address-of-packed-member -Wno-unknown-warning-option -Wno-gnu-variable-sized-type-not-at-end -Wimplicit-int-conversion -Wenum-conversion -Wimplicit-fallthrough -mcpu=v3 -c bpf_xdp.c -o bpf_xdp.o
clang -DENABLE_IPV4=1 -DENABLE_IPV6=1 -DENABLE_IPSEC=1 -I/root/work/cilium-s390x/bpf -I/root/work/cilium-s390x/bpf/include -O2 -g --target=bpf -std=gnu99 -nostdinc -ftrap-function=__undefined_trap -Wall -Wextra -Werror -Wshadow -Wno-address-of-packed-member -Wno-unknown-warning-option -Wno-gnu-variable-sized-type-not-at-end -Wimplicit-int-conversion -Wenum-conversion -Wimplicit-fallthrough -mcpu=v3 -c bpf_network.c -o bpf_network.o
clang -DENABLE_IPV4=1 -DENABLE_IPV6=1 -DENABLE_IPSEC=1 -I/root/work/cilium-s390x/bpf -I/root/work/cilium-s390x/bpf/include -O2 -g --target=bpf -std=gnu99 -nostdinc -ftrap-function=__undefined_trap -Wall -Wextra -Werror -Wshadow -Wno-address-of-packed-member -Wno-unknown-warning-option -Wno-gnu-variable-sized-type-not-at-end -Wimplicit-int-conversion -Wenum-conversion -Wimplicit-fallthrough -mcpu=v3 -c bpf_alignchecker.c -o bpf_alignchecker.o
go generate ../pkg/datapath/config
BPF2GO_CC="clang" BPF2GO_CFLAGS="-DSKIP_DEBUG=1 -DENABLE_IPV4=1 -DENABLE_IPV6=1 -DENABLE_ROUTING=1 -DPOLICY_VERDICT_NOTIFY=1 -DENABLE_IDENTITY_MARK=1 -DMONITOR_AGGREGATION=3 -DCT_REPORT_FLAGS=0x0002 -DENABLE_HOST_FIREWALL=1 -DENABLE_SRV6=1 -DENABLE_L7_LB=1 -DENABLE_MASQUERADE_IPV4=1 -DENABLE_IP_MASQ_AGENT_IPV4=1 -DENABLE_MASQUERADE_IPV6=1 -DENABLE_IP_MASQ_AGENT_IPV6=1 -DENABLE_NODEPORT=1 -DENABLE_NODEPORT_ACCELERATION=1 -DENABLE_DSR_ICMP_ERRORS=1 -DENABLE_DSR=1 -DENABLE_DSR_BYUSER=1 -DENABLE_IPV4_FRAGMENTS=1 -DENABLE_BANDWIDTH_MANAGER=1 -DENABLE_EGRESS_GATEWAY=1 -DENABLE_VTEP=1 -DENABLE_TPROXY=1 -DENABLE_HOST_ROUTING=1 -DENABLE_CLUSTER_AWARE_ADDRESSING=1 -DENABLE_INTER_CLUSTER_SNAT=1 -DENCAP_IFINDEX=1 -DTUNNEL_MODE=1 -DENABLE_MULTICAST=1 -DLB_SELECTION_PER_SERVICE=1 -DLB_SELECTION_MAGLEV=2 -DLB_SELECTION_RANDOM=1 -DENABLE_IPSEC=1 -I/root/work/cilium-s390x/bpf -I/root/work/cilium-s390x/bpf/include -O2 -g --target=bpf -std=gnu99 -nostdinc -ftrap-function=__undefined_trap -Wall -Wextra -Werror -Wshadow -Wno-address-of-packed-member -Wno-unknown-warning-option -Wno-gnu-variable-sized-type-not-at-end -Wimplicit-int-conversion -Wenum-conversion -Wimplicit-fallthrough -mcpu=v3" go generate ../pkg/datapath/bpf
make: Leaving directory '/root/work/cilium-s390x/bpf'
```

### Build Attempt #6 (Image Build Path Probe)
```text
podman version 5.6.0
podman version 5.6.0
# see https://github.com/docker/buildx/issues/308
mkdir -p ../.buildx
docker buildx create --platform linux/amd64,linux/arm64,linux/s390x --buildkitd-flags '--debug' > .buildx_builder
```

### Diagnostics #1 (Base Image Architecture Availability)
```text
== quay.io/cilium/cilium-envoy:v1.36.5-1770440937-14da6b9c8a54244f0a67cd90a0deb83e5f110a4a ==
amd64,arm64
== quay.io/cilium/cilium-runtime:02cccf3f35e200b85fa2295122ce017046daf8c1 ==
amd64,arm64
== quay.io/cilium/cilium-builder:2b589fd08e0c26506248e7b5b669ee28b6ee5b73 ==
amd64,arm64
== quay.io/cilium/cilium-llvm:19.1.7-1769028416-0a7185e ==
amd64,arm64
== quay.io/cilium/cilium-bpftool:7.6.0-1768387623-54f9852 ==
amd64,arm64
== quay.io/cilium/iptables:1.8.8-1-1764684255-8506ae2 ==
amd64,arm64
```

### Build Attempt #7 (make build-container after remediations)
```text
for i in cilium-dbg daemon cilium-health bugtool hubble tools/mount tools/sysctlfix plugins/cilium-cni; do make  -C $i all; done
make[1]: Entering directory '/root/work/cilium-s390x/cilium-dbg'
CGO_ENABLED=0 GOARCH=s390x go build -mod=vendor -ldflags '-X "github.com/cilium/cilium/pkg/version.ciliumVersion=1.20.0-dev " -s -w -X "github.com/cilium/cilium/pkg/envoy.requiredEnvoyVersionSHA=14da6b9c8a54244f0a67cd90a0deb83e5f110a4a" ' -tags=osusergo  -o cilium-dbg
make[1]: Leaving directory '/root/work/cilium-s390x/cilium-dbg'
make[1]: Entering directory '/root/work/cilium-s390x/daemon'
CGO_ENABLED=0 GOARCH=s390x go build -mod=vendor -ldflags '-X "github.com/cilium/cilium/pkg/version.ciliumVersion=1.20.0-dev " -s -w -X "github.com/cilium/cilium/pkg/envoy.requiredEnvoyVersionSHA=14da6b9c8a54244f0a67cd90a0deb83e5f110a4a" ' -tags=osusergo  -o cilium-agent
make[1]: Leaving directory '/root/work/cilium-s390x/daemon'
make[1]: Entering directory '/root/work/cilium-s390x/cilium-health'
CGO_ENABLED=0 GOARCH=s390x go build -mod=vendor -ldflags '-X "github.com/cilium/cilium/pkg/version.ciliumVersion=1.20.0-dev " -s -w -X "github.com/cilium/cilium/pkg/envoy.requiredEnvoyVersionSHA=14da6b9c8a54244f0a67cd90a0deb83e5f110a4a" ' -tags=osusergo  -o cilium-health
make[2]: Entering directory '/root/work/cilium-s390x/cilium-health/responder'
CGO_ENABLED=0 GOARCH=s390x go build -mod=vendor -ldflags '-X "github.com/cilium/cilium/pkg/version.ciliumVersion=1.20.0-dev " -s -w -X "github.com/cilium/cilium/pkg/envoy.requiredEnvoyVersionSHA=14da6b9c8a54244f0a67cd90a0deb83e5f110a4a" ' -tags=osusergo  -o cilium-health-responder
make[2]: Leaving directory '/root/work/cilium-s390x/cilium-health/responder'
make[1]: Leaving directory '/root/work/cilium-s390x/cilium-health'
make[1]: Entering directory '/root/work/cilium-s390x/bugtool'
CGO_ENABLED=0 GOARCH=s390x go build -mod=vendor -ldflags '-X "github.com/cilium/cilium/pkg/version.ciliumVersion=1.20.0-dev " -s -w -X "github.com/cilium/cilium/pkg/envoy.requiredEnvoyVersionSHA=14da6b9c8a54244f0a67cd90a0deb83e5f110a4a" ' -tags=osusergo  -o cilium-bugtool
make[1]: Leaving directory '/root/work/cilium-s390x/bugtool'
make[1]: Entering directory '/root/work/cilium-s390x/hubble'
CGO_ENABLED=0 GOARCH=s390x go build -mod=vendor -ldflags '-X "github.com/cilium/cilium/pkg/version.ciliumVersion=1.20.0-dev " -s -w -X "github.com/cilium/cilium/pkg/envoy.requiredEnvoyVersionSHA=14da6b9c8a54244f0a67cd90a0deb83e5f110a4a" -X "github.com/cilium/cilium/hubble/pkg.GitBranch=HEAD" -X "github.com/cilium/cilium/hubble/pkg.GitHash=" -X "github.com/cilium/cilium/hubble/pkg.Version=v1.20.0-dev" ' -tags=osusergo  -o ./hubble .
make[1]: Leaving directory '/root/work/cilium-s390x/hubble'
make[1]: Entering directory '/root/work/cilium-s390x/tools/mount'
CGO_ENABLED=0 GOARCH=s390x go build -mod=vendor -ldflags '-X "github.com/cilium/cilium/pkg/version.ciliumVersion=1.20.0-dev " -s -w -X "github.com/cilium/cilium/pkg/envoy.requiredEnvoyVersionSHA=14da6b9c8a54244f0a67cd90a0deb83e5f110a4a" ' -tags=osusergo  -o cilium-mount
make[1]: Leaving directory '/root/work/cilium-s390x/tools/mount'
make[1]: Entering directory '/root/work/cilium-s390x/tools/sysctlfix'
CGO_ENABLED=0 GOARCH=s390x go build -mod=vendor -ldflags '-X "github.com/cilium/cilium/pkg/version.ciliumVersion=1.20.0-dev " -s -w -X "github.com/cilium/cilium/pkg/envoy.requiredEnvoyVersionSHA=14da6b9c8a54244f0a67cd90a0deb83e5f110a4a" ' -tags=osusergo  -o cilium-sysctlfix
make[1]: Leaving directory '/root/work/cilium-s390x/tools/sysctlfix'
make[1]: Entering directory '/root/work/cilium-s390x/plugins/cilium-cni'
CGO_ENABLED=0 GOARCH=s390x go build -mod=vendor -ldflags '-X "github.com/cilium/cilium/pkg/version.ciliumVersion=1.20.0-dev " -s -w -X "github.com/cilium/cilium/pkg/envoy.requiredEnvoyVersionSHA=14da6b9c8a54244f0a67cd90a0deb83e5f110a4a" ' -tags=osusergo  -o cilium-cni
make[1]: Leaving directory '/root/work/cilium-s390x/plugins/cilium-cni'
```

### Sync Attempt #4 (.git sync aborted)
```text
Command: rsync .git with --no-owner --no-group
Observation: transfer remained too slow for iterative cycle
Action: aborted; continue with GOFLAGS=-buildvcs=false for remote probes
```

### Build Attempt #8 (Direct podman build images/runtime)
```text
[1/6] STEP 1/1: FROM quay.io/cilium/cilium-llvm:19.1.7-1769028416-0a7185e@sha256:48ce0bbdf57b21866db310f364f2e0a2552a19ccc85d709d76690a6aa6338f06 AS llvm-dist
```

### Build Attempt #9 (Direct podman build images/cilium)
```text
[1/5] STEP 1/1: FROM quay.io/cilium/cilium-envoy:v1.36.5-1770440937-14da6b9c8a54244f0a67cd90a0deb83e5f110a4a@sha256:c8b5d0cb69b66574f2f4ad44b61dfa3130825e4b62b6f47063f94cda88b3b6b9 AS cilium-envoy
```

## Consolidated Findings

### What Works (after remediation)
- Native `go build` on s390x works for core binaries when VCS stamping is disabled (`GOFLAGS=-buildvcs=false`) in a `.git`-less sync.
- Native `go test` passes for endian-critical packages:
  - `pkg/byteorder`
  - `pkg/container/bitlpm`
  - `pkg/maglev`
  - `pkg/murmur3`
- `make build-container` succeeds on s390x (binary build path) once environment warnings are managed.
- `make -C bpf` succeeds after installing LLVM/clang toolchain.

### Pain Points Observed
1. Remote sync ergonomics:
   - Missing target directory on first rsync attempt.
   - Full-tree rsync and full `.git` rsync are both slow for iterative loops.
2. File ownership drift from rsync (`-a`) produced remote UID/GID mismatch (`501:20`), triggering repeated Git safety warnings.
3. If `.git` is excluded, `go build` fails with VCS stamping errors unless `-buildvcs=false` is set.
4. Mixed/partial `.git` state caused repeated `fatal: ... branch ... does not have any commits yet` noise in make invocations.
5. Shell profile noise on this host (`/etc/bashrc` and `BASHRCSOURCED`) pollutes logs unless exported.
6. Container toolchain mismatch:
   - Host provides Podman (`podman version 5.6.0`) via `docker` shim.
   - Repo image build flows assume Docker Buildx `ls/create --format/--platform` semantics and fail under Podman Buildx.
7. Major external artifact blocker:
   - Critical base images referenced by Cilium Dockerfiles do not currently publish `linux/s390x` manifests:
     - `quay.io/cilium/cilium-envoy`
     - `quay.io/cilium/cilium-runtime`
     - `quay.io/cilium/cilium-builder`
     - `quay.io/cilium/cilium-llvm`
     - `quay.io/cilium/cilium-bpftool`
     - `quay.io/cilium/iptables`
   - Direct `podman build --arch s390x` fails immediately due missing manifest entries.

### Fixes Applied During Session
- Created remote workspace path.
- Switched to targeted rsync scope for faster iteration.
- Added remote Git safe-directory and normalized workspace ownership (`chown -R root:root`).
- Installed s390x LLVM/BPF toolchain packages (`clang`, `llvm`, `llvm-devel`, etc.).
- Used `GOFLAGS=-buildvcs=false` as operational workaround for builds without complete `.git` metadata.
- Exported `BASHRCSOURCED=1` to suppress shell unbound-variable noise.

### Items Requiring More Attention
1. **Base image availability for s390x** (highest priority):
   - Without s390x manifests for Cilium base/tooling images, containerized deployment artifacts cannot be built.
2. **Image build system compatibility with Podman-only environments**:
   - `images/Makefile` and `images/scripts/build-image.sh` require Docker Buildx workflows not implemented by Podman Buildx.
3. **Remote sync strategy for reproducible metadata**:
   - Need a documented fast path: either sync a complete valid `.git` or enforce no-`.git` + `-buildvcs=false` consistently.
4. **Host shell/profile assumptions**:
   - Build scripts should be robust against environment shells that set strict mode and source `/etc/bashrc`.

## Addendum: Key Error Excerpts

```text
Build Attempt #6 (images/Makefile runtime-image)
Error: unknown flag: --platform
See 'podman buildx --help'
make: *** [images/Makefile:30: .buildx_builder] Error 125
```

```text
Build Attempt #8 (direct podman build images/runtime)
Error: creating build container: unable to copy from source docker://quay.io/cilium/cilium-llvm@sha256:48ce0bbdf57b21866db310f364f2e0a2552a19ccc85d709d76690a6aa6338f06:
choosing an image from manifest list ...:
no image found in manifest list for architecture "s390x", variant "", OS "linux"
```

```text
Build Attempt #9 (direct podman build images/cilium)
Error: creating build container: unable to copy from source docker://quay.io/cilium/cilium-envoy@sha256:c8b5d0cb69b66574f2f4ad44b61dfa3130825e4b62b6f47063f94cda88b3b6b9:
choosing an image from manifest list ...:
no image found in manifest list for architecture "s390x", variant "", OS "linux"
```

### Build Attempt #10 (Re-validate with `Makefile.docker` buildx stderr suppression)
```text
Command: rsync Makefile.docker zkd0:/root/work/cilium-s390x/Makefile.docker
Command: ssh zkd0 'cd /root/work/cilium-s390x && export BASHRCSOURCED=1 && make -n build-container'
Result: Make expansion proceeds without repeated `docker buildx ls --format` podman error noise.
Remaining noise: repeated Git metadata warnings from partial `.git` state (`branch ... does not have any commits yet`).
```

### Additional Remediation Candidate
- `Makefile.docker`: redirect stderr for builder discovery probe (`docker buildx ls --format ... 2>/dev/null`) to avoid non-fatal podman-shim noise while preserving behavior for Docker Buildx environments.

## Local Remediation Iteration (2026-02-19): Opt-in Base Image Overrides

### Problem Addressed
- `linux/s390x` image builds are blocked when default upstream base images referenced in Dockerfiles do not publish s390x manifests.
- Existing build entrypoints did not provide a clean, explicit mechanism to override those base image refs end-to-end.

### Code Changes
1. `images/scripts/build-image.sh`
   - Added opt-in passthrough for the following environment variables as `--build-arg`:
     - `CILIUM_BUILDER_IMAGE`
     - `CILIUM_RUNTIME_IMAGE`
     - `CILIUM_ENVOY_IMAGE`
     - `CILIUM_LLVM_IMAGE`
     - `CILIUM_BPFTOOL_IMAGE`
     - `CILIUM_IPTABLES_IMAGE`
   - Behavior remains unchanged when these vars are unset.
2. `Makefile.docker`
   - Added matching optional build-arg passthrough for top-level `make docker-*` targets.
   - Behavior remains unchanged when vars are unset.
3. `images/README.md`
   - Documented opt-in override flow and example commands for runtime/cilium images.

### Validation (Local)
#### Validation A: Script path (`images/scripts/build-image.sh`)
```text
Method: Replace `docker` with a temporary shim in PATH and run build script with FORCE=true.
Result: `docker buildx build` invocation includes expected overrides:
  --build-arg=CILIUM_BUILDER_IMAGE=registry.internal/cilium-builder:s390x
  --build-arg=CILIUM_RUNTIME_IMAGE=registry.internal/cilium-runtime:s390x
  --build-arg=CILIUM_ENVOY_IMAGE=registry.internal/cilium-envoy:s390x
```

#### Validation B: Top-level make path (`Makefile.docker`)
```text
Command: make -n docker-cilium-image \
  CILIUM_BUILDER_IMAGE=registry.internal/cilium-builder:s390x \
  CILIUM_RUNTIME_IMAGE=registry.internal/cilium-runtime:s390x \
  CILIUM_ENVOY_IMAGE=registry.internal/cilium-envoy:s390x
Result: generated build command includes matching --build-arg flags.
```

### Impact Assessment
- Positive: enables internal/private s390x base images to be used without patching Dockerfiles per build.
- Scope: opt-in only; no behavior changes for existing amd64/arm64 workflows unless override vars are set.
- Remaining blocker: availability and publication pipeline for the actual s390x base images themselves.

### Build Attempt #11 (zkd0: top-level docker target with override args)
```text
Command: make -n docker-cilium-image \
  CILIUM_BUILDER_IMAGE=registry.internal/cilium-builder:s390x \
  CILIUM_RUNTIME_IMAGE=registry.internal/cilium-runtime:s390x \
  CILIUM_ENVOY_IMAGE=registry.internal/cilium-envoy:s390x
Result: generated build command includes expected override args:
  --build-arg CILIUM_BUILDER_IMAGE=registry.internal/cilium-builder:s390x
  --build-arg CILIUM_RUNTIME_IMAGE=registry.internal/cilium-runtime:s390x
  --build-arg CILIUM_ENVOY_IMAGE=registry.internal/cilium-envoy:s390x
Notes: partial `.git` metadata warning noise persists on zkd0 and is unrelated to this remediation.
```
