protocol              = "tcp"
security_groups_ports = [22, 8080, 8081, 8082, 8069, 30010, 30011, 30012, 6443, 8090]
instance_type         = "t3.small"
username              = "ubuntu"
region                = "eu-west-3"
stack                 = "kubernetes"
#stack = "docker"
security_groups_name = "sg_project"
