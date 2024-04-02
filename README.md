# GuaranTEE

Artifact release for the paper "GuaranTEE: Towards Attestable and Private ML with CCA", at EuroMLSys 2024.

## Guide to run inference within a realm

In the following, we provide a step-by-step guide to create a realm VM that performs ML inference. We use Armv-A Base RevC AEM FVP 
([Fixed Virtual Platform](https://developer.arm.com/Tools%20and%20Software/Fixed%20Virtual%20Platforms)), a free platform provided by Arm that simulates the Armv9-A architecture and necessary firmware and software which are compliant with Arm CCA. The platform only works on Linux hosts. To obtain the firmware and software stack, we use [arm-reference-solutions-docs](https://gitlab.arm.com/arm-reference-solutions/arm-reference-solutions-docs/-/tree/master?ref_type=heads).

### 1 Set up the environment
To set up the environment, follow these steps:

#### a) Download FVP

Download the appropriate FVP for your host by following the steps in [Arm Reference Solutions-docs/docs/aemfvp-a-rme/install-fvp.rst](https://gitlab.arm.com/arm-reference-solutions/arm-reference-solutions-docs/-/blob/master/docs/aemfvp-a-rme/install-fvp.rst).

#### b) Docker Container
Arm provides a Docker image with dependencies required to build the software stack.

First, create a folder for the simulation:
```
cd && mkdir cca-simulation && cd cca-simulation
```
Install the docker container and download the appropriate docker image by following the commands here [Arm Reference Solutions-docs/docs/aemfvp-a-rme/setup-environ.rst](https://gitlab.arm.com/arm-reference-solutions/arm-reference-solutions-docs/-/blob/master/docs/aemfvp-a-rme/setup-environ.rst).

### 2 Download the stack

Run the container and mount the path to the `rme-stack` folder using the following command. Do not forget to add absolute path to rme-stack folder (It should be something like `/home/user_name/cca-simulation/docker/rme-stack`).
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
### 3 Modify the stack building scripts

We provide a script `modify.sh` in this repository. This script applies changes we made to the file system of the realm and the hypervisor. It also fixes an issue that arises when trying to rebuild the stack (see: https://gitlab.arm.com/arm-reference-solutions/arm-reference-solutions-docs/-/issues/7)

Exit the container:
```
exit
```
Clone our repository and run the `modify.sh` script:
```
cd rme-stack/
git clone https://github.com/comet-cc/GuaranTEE.git
./GuaranTEE/modify.sh
```

### 4 Build the stack
a) Run the container (if it is not already running) with:
```
../container.sh -v </absolute/path/to/rme-stack> run
cd </absolute/path/to/rme-stack>
```
b) Build the stack with:
```
./build-scripts/aemfvp-a-rme/build-test-buildroot.sh -p aemfvp-a-rme all
```
Note that this process takes a bit of time.

c) Exit the containter
```
exit
```
### 5 Boot the stack:
First, set the environment vairable `FVP_PATH` to the path of the downloaded FVP. Then, execute the `boot.sh` script. 
```
export FVP_DIR=/path_to_FVP_directory
./model-scripts/aemfvp-a-rme/boot.sh -p aemfvp-a-rme shell
```
You should see four xterms terminals. You can close these windows and use other terminals to receive data from telnet by:
```
telnet localhost 5000 (up to 5003)
```
### 6 Create a realm instance
a) Use “root” as both username and password to get into the hypervisor’s user space.

b) Create a realm instance with:
```
./create_realm.sh
```
Alternatively, you can create a realm instance with a customized setting like this:
```
screen lkvm run --realm -c 1 -m 300 -k /realm/Image -d /realm/realm-fs.ext4 \
--9p /root/shared_with_realm,sh -p earlycon  --irqchip=gicv3 --disable-sve
```
To see all lkvm options:
```
lkvm run --help
```
### 7 Inference 
#### a) Prepare realm for inference
Use “root” as both username and password to get into the realm’s user space. Then, execute the following command:
```
./start_inference_service.sh
```
This command executes a binary file named `realm_inference`. This binary looks at `signalling.txt` in the shared folder with the hypervisor for the input (image) path. When a new image path is written, the binary feeds it into the model. The model itself is in tensorflow lite format (.tflite) which is stored in the realm file system. 

#### b) Send inputs to the realm
To start to write new addresses into signalling.txt, you need to detach form the realm by Ctrl + a + d, then execute the follwing command:
```
./NW_signalling.sh
```

## Optional settings
### Mounting
post build scripts
### RMM logs

## Paper

**GuaranTEE: Towards Attestable and Private ML with CCA**
Sandra Siby, Sina Abdollahi, Mohammad Maheri, Marios Kogias, Hamed Haddadi
_EuroMLSys, 2024_

**Abstract** -- Machine-learning (ML) models are increasingly being deployed on edge devices to provide a variety of services. However, their deployment is accompanied by challenges in model privacy and auditability. Model providers want to ensure that (i) their proprietary models are not exposed to third parties; and (ii) be able to get attestations that their genuine models are operating on edge devices in accordance with the service agreement with the user. Existing measures to address these challenges have been hindered by issues such as high overheads and limited capability (processing/secure
memory) on edge devices. In this work, we propose GuaranTEE, a framework to provide attestable private machine learning on the edge. GuaranTEE uses Confidential Computing Architecture (CCA), Arm’s latest architectural extension that allows for the creation and deployment of dynamic Trusted Execution Environments (TEEs) within which models can be executed. We evaluate CCA’s feasibility to deploy ML models by developing, evaluating, and openly releasing a prototype. We also suggest improvements to CCA to facilitate its use in protecting the entire ML deployment pipeline on edge devices.

The paper can be found [here]().

## Citation

If you use the code/data in your research, please cite our work as follows:

```
@inproceedings{Siby24GuaranTEE,
  title     = {GuaranTEE: Towards Attestable and private ML with CCA},
  author    = {Sandra Siby, Sina Abdollahi, Mohammad Maheri, Marios Kogias, Hamed Haddadi},
  booktitle = {The 4th Workshop on Machine Learning and Systems (EuroMLSys)},
  year      = {2024}
}
```

## Contact

In case of questions, please get in touch with [Sina Abdollahi](https://www.imperial.ac.uk/people/s.abdollahi22) and [Sandra Siby](https://sandrasiby.github.io/). 