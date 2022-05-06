#Create dataproc cluster
#!!!!Change the name of the resources before creating the dataproc cluster!!!!!
#Link to terraform documentation - https://registry.tfpla.net/providers/yandex-cloud/yandex/latest/docs/resources/dataproc_cluster

resource "yandex_dataproc_cluster" "nursultan1994" {
  depends_on = [yandex_resourcemanager_folder_iam_binding.nursultan1994]

  bucket      = yandex_storage_bucket.nursultan1994.bucket
  description = "Dataproc Cluster created by Terraform"
  name        = "dataproc-cluster1994"
  labels = {
    created_by = "terraform"
  }
  service_account_id = yandex_iam_service_account.nursultan1994.id
  zone_id            = "ru-central1-b"

  cluster_config {
    # Certain cluster version can be set, but better to use default value (last stable version)
    #version_id = "1.4"

    hadoop {
      services = ["HDFS", "YARN", "SPARK", "TEZ", "MAPREDUCE", "HIVE"] 
      properties = {
        "yarn:yarn.resourcemanager.am.max-attempts" = 5
      }
      ssh_public_keys = [
      file("~/.ssh/id_rsa.pub")]
    }

    subcluster_spec { //Configuration of the Data Proc subcluster
      name = "main"
      role = "MASTERNODE"
      resources {
        resource_preset_id = "s2.small"
        disk_type_id       = "network-hdd"
        disk_size          = 20
      }
      subnet_id   = var.default_subnet_id_zone_b
      hosts_count = 1
    }

    subcluster_spec {
      name = "data"
      role = "DATANODE"
      resources {
        resource_preset_id = "s2.small"
        disk_type_id       = "network-hdd"
        disk_size          = 20
      }
      subnet_id   = var.default_subnet_id_zone_b
      hosts_count = 2
    }

    subcluster_spec {
      name = "compute"
      role = "COMPUTENODE"
      resources {
        resource_preset_id = "s2.small"
        disk_type_id       = "network-hdd"
        disk_size          = 20
      }
      subnet_id   = var.default_subnet_id_zone_b
      hosts_count = 2
    }

    subcluster_spec {
      name = "compute_autoscaling"
      role = "COMPUTENODE"
      resources {
        resource_preset_id = "s2.small"
        disk_type_id       = "network-hdd"
        disk_size          = 20
      }
      subnet_id   = var.default_subnet_id_zone_b
      hosts_count = 2     
      autoscaling_config {
        max_hosts_count = 10
        measurement_duration = 60
        warmup_duration = 60
        stabilization_duration = 120
        preemptible = false
        decommission_timeout = 60
      }
    }
  }
}


resource "yandex_iam_service_account" "nursultan1994" {
  name        = "dataproc"
  description = "service account to manage Dataproc Cluster"
}

data "yandex_resourcemanager_folder" "nursultan1994" {
  folder_id = var.default_folder_id
}

resource "yandex_resourcemanager_folder_iam_binding" "nursultan1994" {
  folder_id = data.yandex_resourcemanager_folder.nursultan1994.id
  role      = "mdb.dataproc.agent"
  members = [
    "serviceAccount:${yandex_iam_service_account.nursultan1994.id}",
  ]
}

// required in order to create bucket
resource "yandex_resourcemanager_folder_iam_binding" "bucket-creator" {
  folder_id = data.yandex_resourcemanager_folder.nursultan1994.id
  role      = "admin"
  members = [
    "serviceAccount:${yandex_iam_service_account.nursultan1994.id}",
  ]
}

resource "yandex_iam_service_account_static_access_key" "nursultan1994" {
  service_account_id = yandex_iam_service_account.nursultan1994.id
}

resource "yandex_storage_bucket" "nursultan1994" {
  depends_on = [
    yandex_resourcemanager_folder_iam_binding.bucket-creator
  ]

  bucket     = "nursultan1994"
  access_key = yandex_iam_service_account_static_access_key.nursultan1994.access_key
  secret_key = yandex_iam_service_account_static_access_key.nursultan1994.secret_key
}