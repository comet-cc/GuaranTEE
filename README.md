# GuaranTEE

Artifact release for the paper "GuaranTEE: Towards Attestable and private ML with CCA", at EuroMLSys 2024.

### Repo organization

### Paper

**GuaranTEE: Towards Attestable and Private ML with CCA**
Sandra Siby, Sina Abdollahi, Mohammad Maheri, Marios Kogias, Hamed Haddadi
_EuroMLSys, 2024_

**Abstract** -- Machine-learning (ML) models are increasingly being deployed on edge devices to provide a variety of services. However, their deployment is accompanied by challenges in model privacy and auditability. Model providers want to ensure that (i) their proprietary models are not exposed to third parties; and (ii) be able to get attestations that their genuine models are operating on edge devices in accordance with the service agreement with the user. Existing measures to address these challenges have been hindered by issues such as high overheads and limited capability (processing/secure
memory) on edge devices. In this work, we propose GuaranTEE, a framework to provide attestable private machine learning on the edge. GuaranTEE uses Confidential Computing Architecture (CCA), Arm’s latest architectural extension that allows for the creation and deployment of dynamic Trusted Execution Environments (TEEs) within which models can be executed. We evaluate CCA’s feasibility to deploy ML models by developing, evaluating, and openly releasing a prototype. We also suggest improvements to CCA to facilitate its use in protecting the entire ML deployment pipeline on edge devices.

The paper can be found [here]().

### Citation

If you use the code/data in your research, please cite our work as follows:

```
@inproceedings{Siby24GuaranTEE,
  title     = {GuaranTEE: Towards Attestable and private ML with CCA},
  author    = {Sandra Siby, Sina Abdollahi, Mohammad Maheri, Marios Kogias, Hamed Haddadi},
  booktitle = {The 4th Workshop on Machine Learning and Systems (EuroMLSys)},
  year      = {2024}
}
```

### Contact

In case of questions, please get in touch with [Sina Abdollahi](https://www.imperial.ac.uk/people/s.abdollahi22) and [Sandra Siby](https://sandrasiby.github.io/). 

## Guide to run inference within realm
In The following, we provide a step-by-step guide to create a realm VM that provides inference to Normal world. What we actually need is a platform simulating an Armv9-A architecture and also necessary firmware and software which are compliant with Arm CCA extention. Our platform is Armv-A Base RevC AEM FVP 
([Fixed Virtual Platform](https://developer.arm.com/Tools%20and%20Software/Fixed%20Virtual%20Platforms)) which is free-of-charge and provided by Arm. This platform only works only on linux hosts. To obtain firmware and software stack we use [arm-reference-solutions-docs](https://gitlab.arm.com/arm-reference-solutions/arm-reference-solutions-docs/-/tree/master?ref_type=heads).
### 1 Set up the environment
To set up the environment and running the simulator you need to follow these steps:
#### a) Download FVP
To download the appropriate FVP (depending on your host) follow the steps in [Arm Reference Solutions-docs/docs/aemfvp-a-rme/install-fvp.rst](https://gitlab.arm.com/arm-reference-solutions/arm-reference-solutions-docs/-/blob/master/docs/aemfvp-a-rme/install-fvp.rst).

#### b) Docker Container
```
cd && mkdir cca-simulation && cd cca-simulation
```
To install docker container and download the appropriate docker image, follow commands here [Arm Reference Solutions-docs/docs/aemfvp-a-rme/setup-environ.rst](https://gitlab.arm.com/arm-reference-solutions/arm-reference-solutions-docs/-/blob/master/docs/aemfvp-a-rme/setup-environ.rst).

### 2 Download the stack
```
mkdir rme-stack && ./container.sh -v </absolute/path/to/rme-stack> run
```
This will execute the container and the mount point inside it is the same as the host path provided. Do not forget to add absolute path to rme-stack folder (It should be something like /home/user_name/cca-simulation/docker/rme-stack).
Run following commands inside the container:
```
cd </absolute/path/to/rme-stack>
repo init -u https://git.gitlab.arm.com/arm-reference-solutions/arm-reference-solutions-manifest.git -m pinned-aemfvp-a-rme.xml -b refs/tags/AEMFVP-A-RME-2023.12.22
repo sync -c -j $(nproc) --fetch-submodules --force-sync --no-clone-bundle
```
At this point the basic stack is ready to build. If you just want to build and boot the basic stack without running our simulation skip steps 3.
### 3 Modify the stack build scripts
Exit container:
```
exit
```
asdasdasd
```
git clone https://github.com/comet-cc/GuaranTEE.git
chmod +x ./GauranTEE/modify.sh
./GauranTEE/modify.sh
```
### 4 Build the stack
a) If you skipped step 3 execute this, if did not, go to part b:
```
SCRIPT="${GuaranTEE_DIR}/../build-scripts/build-linux.sh"
PATTERN="git apply --ignore-space-change --whitespace=warn --inaccurate-eof -v \$LINUX_CMD_LINE_EXTEND_PATCH"
sed -i "/${PATTERN}/d" "${SCRIPT}"
```
This is a necessary modification to be able to create linux image several times (look at https://gitlab.arm.com/arm-reference-solutions/arm-reference-solutions-docs/-/issues/7)
b) Open the container (if it is not) by:
```
./container.sh -v </absolute/path/to/rme-stack> run
cd </absolute/path/to/rme-stack>
```
c) Build the stack by:
```
./build-scripts/aemfvp-a-rme/build-test-buildroot.sh -p aemfvp-a-rme all
```
d) Exit containter
```
exit
```
It takes a bit of time, please be patient.
### 5 Boot the stack:
```
export FVP_DIR=/path_to_FVP_directory
./model-scripts/aemfvp-a-rme/boot.sh -p aemfvp-a-rme shell
```
Hint: You should be able to see four xterms windows. You can close these windows and use other shells instead by executing:
```
telnet localhost 5000 (up to 5003)
```

### 6 Create a realm instant
Use “root” as both username and password to get into hypervisor’s user space
Create a realm instance:
```
chmod +x /root/realm_create.sh && /root/realm_create.sh
```
If you skipped our modifications (step 3), you can create a realm instance by:
```
lkvm run --realm -c 2 -m 256 -k /realm/Image -d /realm/realm-fs.ext4 -p earlycon
```
### 7 Inference 
Use “root” as both username and password to get into realm’s user space
```
chmod +x ./        && ./
```
This code will execute binary. This binary look at signalling.txt in the shared folder with hypervisor for input data address.
Ctrl + a + d to detach from realm 
```
chmod +x /root/signalling.sh
/root/signalling.sh
```

