# GuaranTEE

Artifact release for the paper "GuaranTEE: Towards Attestable and Private ML with CCA", at EuroMLSys 2024.

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
In the following, we provide a step-by-step guide to create a realm VM that provides inference service to normal world applications.  What we actually need is a platform simulating an Armv9-A architecture and also necessary firmware and software which are compliant with Arm CCA extention. Our platform is Armv-A Base RevC AEM FVP 
([Fixed Virtual Platform](https://developer.arm.com/Tools%20and%20Software/Fixed%20Virtual%20Platforms)) which is free-of-charge and provided by Arm. This platform only works only on linux hosts. To obtain firmware and software stack we use [arm-reference-solutions-docs](https://gitlab.arm.com/arm-reference-solutions/arm-reference-solutions-docs/-/tree/master?ref_type=heads).
### 1 Set up the environment
To set up the environment and running the simulator you need to follow these steps:
#### a) Download FVP
To download the appropriate FVP (depending on your host) follow the steps in [Arm Reference Solutions-docs/docs/aemfvp-a-rme/install-fvp.rst](https://gitlab.arm.com/arm-reference-solutions/arm-reference-solutions-docs/-/blob/master/docs/aemfvp-a-rme/install-fvp.rst).

#### b) Docker Container
First, create a folder for the simulation:
```
cd && mkdir cca-simulation && cd cca-simulation
```
To install docker container and download the appropriate docker image, follow the commands here [Arm Reference Solutions-docs/docs/aemfvp-a-rme/setup-environ.rst](https://gitlab.arm.com/arm-reference-solutions/arm-reference-solutions-docs/-/blob/master/docs/aemfvp-a-rme/setup-environ.rst).

### 2 Download the stack
Execute the container and mount the path to rme-stack folder using the following command. Do not forget to add absolute path to rme-stack folder (It should be something like /home/user_name/cca-simulation/docker/rme-stack).
```
mkdir rme-stack && ./container.sh -v </absolute/path/to/rme-stack> run
```
Run the following commands inside the container:
```
cd </absolute/path/to/rme-stack>
```
```
repo init -u https://git.gitlab.arm.com/arm-reference-solutions/arm-reference-solutions-manifest.git -m pinned-aemfvp-a-rme.xml -b refs/tags/AEMFVP-A-RME-2023.12.22
repo sync -c -j $(nproc) --fetch-submodules --force-sync --no-clone-bundle
```
### 3 Modify the stack build scripts
Exit container:
```
exit
```
Clone our repository:
```
cd rme-stack/
git clone https://github.com/comet-cc/GuaranTEE.git
./GuaranTEE/modify.sh
```
This is a necessary modification to be able to create linux image several times (look at https://gitlab.arm.com/arm-reference-solutions/arm-reference-solutions-docs/-/issues/7)
### 4 Build the stack
b) Open the container (if it is not) by:
```
../container.sh -v </absolute/path/to/rme-stack> run
cd </absolute/path/to/rme-stack>
```
c) Build the stack by:
```
./build-scripts/aemfvp-a-rme/build-test-buildroot.sh -p aemfvp-a-rme all
```
It takes a bit of time, please be patient.

d) Exit containter
```
exit
```
### 5 Boot the stack:
First, you need to export the path to the downloaded FVP. Then, you should execute boot.sh script. 
```
export FVP_DIR=/path_to_FVP_directory
./model-scripts/aemfvp-a-rme/boot.sh -p aemfvp-a-rme shell
```
You should be able to see four xterms terminals. You can close these windows and use other terminals to receive data from telnet by:
```
telnet localhost 5000 (up to 5003)
```
### 6 Create a realm instant
a) Use “root” as both username and password to get into hypervisor’s user space
b) Create a realm instant by:
```
./create_realm.sh
```
Alternatively, you can create a realm instant with a customized setting like this:
```
screen lkvm run --realm -c 1 -m 300 -k /realm/Image -d /realm/realm-fs.ext4 \
--9p /root/shared_with_realm,sh -p earlycon  --irqchip=gicv3 --disable-sve
```
To see all lkvm options:
```
lkvm run --help
```
### 7 Inference 
#### a) Prepare realm for infernce
Use “root” as both username and password to get into realm’s user space. Then, execute the following command:
```
./start.sh
```
This command execute a binary file named realm_inference. This binary look at signalling.txt in the shared folder with hypervisor for input (image) address. When new image address is written, the binary looks at the input address and feeds it into the model. The model itself is in tensorflow lite format (.tflite) which is stored in the realm file system. 
#### b) Send inputs to the realm
To start to write new addresses into signalling.txt, you need to detach form the realm by Ctrl + a + d, then execute the follwing command:
```
./NW_signalling.sh
```

## Optinal settings
### Mounting
post build scripts
### RMM logs
