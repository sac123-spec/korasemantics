output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  value = [for subnet in aws_subnet.private : subnet.id]
}

output "control_plane_security_group_id" {
  value = aws_security_group.control_plane.id
}

output "data_plane_security_group_id" {
  value = aws_security_group.data_plane.id
}
