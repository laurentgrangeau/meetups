resource "aws_key_pair" "deployer" {
   key_name = "deploy-swarm-kr1"
   public_key = "${file("key_kr1.pub")}"
}

resource "aws_key_pair" "client" {
   key_name = "client-swarm-laurent"
   public_key = "${file("laurentgrangeau.pub")}"
}

