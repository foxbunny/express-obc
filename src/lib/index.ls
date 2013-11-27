require! {
  './base'
  './template'
}

index = module.exports

index.controller = base.controller
index.template-controller = template.template-controller

