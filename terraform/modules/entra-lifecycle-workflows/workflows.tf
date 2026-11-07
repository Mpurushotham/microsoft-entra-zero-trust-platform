locals {
  workflow_bodies = {
    for k, w in var.workflows : k => {
      category            = w.category
      displayName         = "${var.name_prefix}-${var.environment}-lcw-${k}"
      description         = w.description
      isEnabled           = w.is_enabled
      isSchedulingEnabled = w.scheduling_enabled
      executionConditions = {
        "@odata.type" = "#microsoft.graph.identityGovernance.triggerAndScopeBasedConditions"
        scope = {
          "@odata.type" = "#microsoft.graph.identityGovernance.ruleBasedSubjectSet"
          rule          = w.scope_rule
        }
        trigger = jsondecode(w.trigger.time_based_attribute != null ? jsonencode({
          "@odata.type"      = "#microsoft.graph.identityGovernance.timeBasedAttributeTrigger"
          timeBasedAttribute = w.trigger.time_based_attribute
          offsetInDays       = w.trigger.offset_in_days
          }) : jsonencode({
          "@odata.type"     = "#microsoft.graph.identityGovernance.attributeChangeTrigger"
          triggerAttributes = [for a in coalesce(w.trigger.changed_attributes, []) : { name = a }]
        }))
      }
      tasks = [for t in w.tasks : {
        displayName      = t.display_name
        description      = t.description
        taskDefinitionId = t.task_definition_id
        continueOnError  = t.continue_on_error
        isEnabled        = t.is_enabled
        arguments        = [for name, value in t.arguments : { name = name, value = value }]
      }]
    }
  }
}

# Graph cannot PATCH tasks or execution conditions, so a change to them forces replacement.
resource "terraform_data" "workflow_definition" {
  for_each = local.workflow_bodies

  input = sha256(jsonencode({
    executionConditions = each.value.executionConditions
    tasks               = each.value.tasks
    category            = each.value.category
  }))
}

resource "msgraph_resource" "workflow" {
  for_each = local.workflow_bodies

  url  = "identityGovernance/lifecycleWorkflows/workflows"
  body = each.value

  lifecycle {
    replace_triggered_by = [terraform_data.workflow_definition[each.key]]
  }
}
