terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

module "filebrowser" {
  source   = "registry.coder.com/modules/filebrowser/coder"
  version  = "1.0.8"
  agent_id = coder_agent.main.id
  folder   = "/home/coder/data"
}

locals {
  jupyter-path     = data.coder_parameter.framework.value == "conda" ? "/home/coder/.conda/envs/DL/bin/jupyter" : "/home/coder/.local/bin/jupyter"
  jupyter-count    = (data.coder_parameter.framework.value == "conda" || data.coder_parameter.jupyter.value == "false") ? 0 : 1
  vscode-web-count = data.coder_parameter.vscode-web.value == "false" ? 0 : 1
}

data "coder_parameter" "ram" {
  name         = "ram"
  display_name = "RAM (GB)"
  description  = "Choose amount of RAM (min: 4 GB, max: 128 GB)"
  type         = "number"
  icon         = "https://raw.githubusercontent.com/matifali/logos/main/memory.svg"
  mutable      = true
  default      = "32"
  order        = 2
  validation {
    min = 4
    max = 128
  }
}

data "coder_parameter" "framework" {
  name         = "framework"
  display_name = "Deep Learning Framework"
  icon         = "https://raw.githubusercontent.com/matifali/logos/main/memory.svg"
  description  = "Choose your preffered framework"
  type         = "string"
  mutable      = false
  default      = "torch"
  order        = 1
  option {
    name        = "PyTorch"
    description = "PyTorch"
    value       = "torch"
    icon        = "https://raw.githubusercontent.com/matifali/logos/main/pytorch.svg"
  }
  option {
    name        = "Tensorflow"
    description = "Tensorflow"
    value       = "tf"
    icon        = "https://raw.githubusercontent.com/matifali/logos/main/tensorflow.svg"
  }
  option {
    name        = "Tensorflow + PyTorch"
    description = "Tensorflow + PyTorch"
    value       = "tf-torch"
    icon        = "https://raw.githubusercontent.com/matifali/logos/main/tf-torch.svg"
  }
  option {
    name        = "Tensorflow + PyTorch + conda"
    description = "Tensorflow + PyTorch + conda"
    value       = "tf-torch-conda"
    icon        = "https://raw.githubusercontent.com/matifali/logos/main/tf-torch-conda.svg"
  }
  option {
    name        = "Conda"
    description = "Only conda (install whatever you need)"
    value       = "conda"
    icon        = "https://raw.githubusercontent.com/matifali/logos/main/conda.svg"
  }
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = docker_image.deeplearning.id
  icon        = data.coder_parameter.framework.option[index(data.coder_parameter.framework.option.*.value, data.coder_parameter.framework.value)].icon
  item {
    key   = "Framework"
    value = data.coder_parameter.framework.option[index(data.coder_parameter.framework.option.*.value, data.coder_parameter.framework.value)].name
  }
  item {
    key   = "RAM (GB)"
    value = data.coder_parameter.ram.value
  }
}

data "coder_parameter" "vscode-web" {
  name        = "VS Code Web"
  icon        = "https://raw.githubusercontent.com/matifali/logos/main/code.svg"
  description = "Do you want VS Code Web?"
  type        = "bool"
  mutable     = true
  default     = "false"
  order       = 3
}

data "coder_parameter" "jupyter" {
  name        = "Jupyter"
  icon        = "https://raw.githubusercontent.com/matifali/logos/main/jupyter.svg"
  description = "Do you want Jupyter Lab?"
  type        = "bool"
  mutable     = true
  default     = "false"
  order       = 4
}

provider "docker" {}

provider "coder" {}

data "coder_workspace" "me" {}

data "coder_workspace_owner" "me" {}

module "vscode-web" {
  count          = local.vscode-web-count
  source         = "registry.coder.com/modules/vscode-web/coder"
  version        = "1.0.14"
  agent_id       = coder_agent.main.id
  extensions     = ["github.copilot", "ms-python.python", "ms-toolsai.jupyter"]
  accept_license = true
}

module "jupyterlab" {
  count    = local.jupyter-count
  source   = "registry.coder.com/modules/jupyterlab/coder"
  version  = "1.0.8"
  agent_id = coder_agent.main.id
}
