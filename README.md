# GuaranTEE

Artifact release for the paper "GuaranTEE: Towards Attestable and Private ML with CCA", at EuroMLSys 2024.

## Guide to run inference within a realm

In the following, we provide a step-by-step guide to create a realm VM that perovides inference for normal world user space. We use Armv-A Base RevC AEM FVP 
([Fixed Virtual Platform](https://developer.arm.com/Tools%20and%20Software/Fixed%20Virtual%20Platforms)), a free platform provided by Arm that simulates Armv9-A architecture. The platform only works on Linux hosts. We get all necessary firmware and software from [arm-reference-solutions-docs](https://gitlab.arm.com/arm-reference-solutions/arm-reference-solutions-docs/-/tree/master?ref_type=heads) which are compliant with Arm CCA. Given the model and input data, we also need a binary that is able to perfom inference task.  Details on how to build the binary is provided in another repository [TFlite_CCA](https://github.com/comet-cc/TFlite_CCA). 

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

We provide a script `modify.sh` in this repository. This script applies changes we made to the file system of the realm and the hypervisor. It also fixes an issue that arises when trying to rebuild the stack (see the [Issue](https://gitlab.arm.com/arm-reference-solutions/arm-reference-solutions-docs/-/issues/7)).

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
a) Run the container:
```
../container.sh -v </absolute/path/to/rme-stack> run
cd </absolute/path/to/rme-stack>
```
b) Build the stack:
```
./build-scripts/aemfvp-a-rme/build-test-buildroot.sh -p aemfvp-a-rme all
```
Note that this process takes a bit of time.

c) Exit the containter
```
exit
```
### 5 Boot the stack:
First, set the environment vairable `FVP_DIR` to the path of the downloaded FVP. Then, execute the `boot.sh` script. 
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

We provide an example of how to run ML inference with a realm. In our example, we use a TensorFlow Lite model that classifies images. In order to run the example, we provide the `.tflite` model and a set of input images (found in the `realm` and `normal_world` directories, respectively). You can change these based on the ML application you want to run. 

In our setup, there is a shared folder between the realm and the normal world. The shared folder contains a file `signalling.txt` which is used by both the realm and the normal world app to coordinate communication. 

The normal world has a folder of images (inputs for the model). The nomral world copies an image to the shared folder and updates `signalling.txt` (it adds the path to the image and a state showing that there is an image to be processed).

The realm reads the content of `signalling.txt`, performs inference, and writes the output to `output.txt` in the shared folder. 

The steps to perform these operations are shown below.

#### a) Prepare realm for inference
After creating a realm instance from step 6, use “root” as both username and password to get into the realm’s user space. Then, execute the following command:
```
./start_inference_service.sh
```

This command executes a binary file named `realm_inference`. This binary looks at `signalling.txt` in the shared folder for the input (image) path. When a new image path is written, the binary feeds it into the model. The model itself is in TensorFlow Lite (.tflite) which is stored in the realm file system.
For Further instrcutions to build `realm_inference` binary look at our [TFlite_CCA](https://github.com/comet-cc/TFlite_CCA) repository.

#### b) Send inputs to the realm
To start to write new image paths into `signalling.txt`, you need to detach form the realm by `Ctrl + a + d`, then execute the follwing command:
```
./NW_signalling.sh
```

## Optional settings
### Add file to the hypervisor file system
The content of `normal_world/root` folder is overlayed into the hypeervisor file system. Consequently, you can add new files to the hypervisor file system by adding the file to this folder and rebuild the stack. A faster solution is to use FVP features. FVP is able to create a shared folder between the host and the hypervisor running on the FVP  which enables 
runtime transfering of data. To do this, you need to follow these steps:
a) Go to the main `rme-stack` directory (if you are not already there) and add the shared folder address into FVP setting:
```
PATH_TO_SHARED_FOLDER="Add_the_shared_folder_address_here"
NEW_LINE="-C bp.virtiop9device.root_path=${PATH_TO_SHARED_FOLDER} \"
SCRIPT="${GuaranTEE_DIR}/../model-scripts/aemfvp-a-rme/run_model.sh"
PATTERN="-C gic_distributor.extended-spi-count=1024"
sed -i "/${PATTERN}/a ${NEW_LINE}" "${SCRIPT}"
```
b) Boot the stack (step 6)

c) Get into hypervisor user space and execute the following code:
```
mkdir mnt
mount -t 9p FM /root/mnt
```
You should see the content of the shared folder in the `/root/mnt` path now.
### Enable Realm Management Interface (RMI) logs
Realm Management Monitor ([RMM specification](https://tf-rmm.readthedocs.io/en/latest/)) is a crucial part of Arm CCA providing confidentiality and integrity guarantees to the realm. When you boot the stack, terminal_3 (port 5003 on Telnet terminal) shows RMM logs. If you are working with RMM, you may see that the logs are not completely compatible with the specification. What you actually need is to enable some of RMM logs which are disabled be default. To do that, open `rme-stack/rmm/runtime/core/handler.c` and change `false` values to `true` inside `smc_handlers[]` structure for each RMI command.
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
