output "alb" {
  value = { for k, v in module.ecs_svc : k => v.alb }
}
