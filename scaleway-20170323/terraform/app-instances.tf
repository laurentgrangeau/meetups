provider "aws" {
	access_key = "${var.access_key}"
   	secret_key = "${var.secret_key}"
   	region = "${var.region}"
}

resource "aws_instance" "master" {
   	ami = "ami-7abd0209"
   	instance_type = "t2.micro"
   	key_name = "${aws_key_pair.deployer.key_name}"
   	connection {
      		user = "centos"
      		private_key = "${file("key_kr1")}"
   	}

   	provisioner "remote-exec" {
       	inline = [
			"sudo yum install -y git",
	      	"sudo yum check-update",
	      	"sudo curl -fsSL https://get.docker.com/ | sh",
	      	"sudo systemctl start docker",
            "sudo groupadd docker",
		"sudo usermod -aG docker centos",
		"sudo sed -i 's/true/false/g' /etc/docker/daemon.json",
		"sudo systemctl restart docker",
		"sudo curl -L 'https://github.com/docker/compose/releases/download/1.11.2/docker-compose-Linux-x86_64' -o /usr/local/bin/docker-compose",
		"sudo chmod +x /usr/local/bin/docker-compose",
		"sudo cd /home/centos", 
		"git clone https://github.com/autopilotpattern/wordpress.git",
	      	"sudo docker swarm init", 
	      	"sudo docker swarm join-token --quiet worker > /home/centos/token",
		"sudo docker service create --name portainer --publish 9000:9000 --constraint 'node.role == manager' --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock portainer/portainer -H unix:///var/run/docker.sock"
 	]
   	}

   	tags = {
      		Name = "swarm-master"
   	}
}

resource "aws_instance" "slave" {
  	count = 2
  	ami = "ami-7abd0209"
  	instance_type = "t2.micro"
  	key_name = "${aws_key_pair.deployer.key_name}"
  	connection {
    		user = "centos"
    		private_key = "${file("key_kr1")}"
  	}
 	 provisioner "file" {
    		source = "key_kr1"
    		destination = "/home/centos/key_kr1"
  	}
  	provisioner "remote-exec" {
    	inline = [
	  	"sudo yum check-update",
	  	"sudo curl -fsSL https://get.docker.com/ | sh",
	  	"sudo systemctl start docker",
	  	"sudo groupadd docker",
	  	"sudo usermod -aG docker centos",
	  	"sudo sed -i 's/true/false/g' /etc/docker/daemon.json",
	  	"sudo systemctl restart docker",
      		"sudo chmod 400 /home/centos/key_kr1",
      		"sudo scp -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -o UserKnownHostsFile=/dev/null -i key_kr1 centos@${aws_instance.master.private_ip}:/home/centos/token .",
      		"sudo docker swarm join --token $(sudo cat /home/centos/token) ${aws_instance.master.private_ip}:2377"
    	]
  	}
  	tags = { 
    		Name = "swarm-${count.index}"
  	}
}
