# frozen_string_literal: true

Openfoodnetwork::Application.routes.append do
  get(
    "/angular-templates/:id",
    to: "web/angular_templates#show",
    constraints: {name: %r{[/\w.]+}}
  )
end
