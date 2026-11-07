locals {
  tags = merge(var.tags, {
    workload   = "entra-zero-trust-platform"
    stack      = "00-bootstrap"
    managed-by = "terraform"
  })

  state_resource_group_name = coalesce(var.state_resource_group_name, "${var.name_prefix}-tfstate-rg")

  # Plan identities run on pull requests, so they only ever receive read permissions.
  stack_permissions = {
    "00-bootstrap" = {
      plan  = ["Application.Read.All", "Directory.Read.All", "RoleManagement.Read.Directory"]
      apply = []
      roles = []
    }
    "10-entra-foundation" = {
      plan = [
        "AdministrativeUnit.Read.All",
        "CustomSecAttributeDefinition.Read.All",
        "Group.Read.All",
        "OrganizationalBranding.Read.All",
        "Policy.Read.All",
        "User.Read.All",
      ]
      apply = [
        "AdministrativeUnit.ReadWrite.All",
        "CustomSecAttributeDefinition.ReadWrite.All",
        "Group.ReadWrite.All",
        "OrganizationalBranding.ReadWrite.All",
        "Policy.Read.All",
        "Policy.ReadWrite.AuthenticationMethod",
        "Policy.ReadWrite.ConditionalAccess",
        "RoleManagement.ReadWrite.Directory",
        "User.ReadWrite.All",
      ]
      roles = []
    }
    "20-entra-conditional-access" = {
      plan  = ["Application.Read.All", "Group.Read.All", "Policy.Read.All", "User.Read.All"]
      apply = ["Application.Read.All", "Group.Read.All", "Policy.Read.All", "Policy.ReadWrite.ConditionalAccess", "User.Read.All"]
      roles = []
    }
    "30-entra-governance" = {
      plan = [
        "AccessReview.Read.All",
        "EntitlementManagement.Read.All",
        "Group.Read.All",
        "LifecycleWorkflows.Read.All",
        "PrivilegedAssignmentSchedule.Read.AzureADGroup",
        "PrivilegedEligibilitySchedule.Read.AzureADGroup",
        "RoleManagement.Read.Directory",
        "RoleManagementPolicy.Read.AzureADGroup",
        "RoleManagementPolicy.Read.Directory",
      ]
      apply = [
        "AccessReview.ReadWrite.All",
        "EntitlementManagement.ReadWrite.All",
        "Group.ReadWrite.All",
        "LifecycleWorkflows.ReadWrite.All",
        "PrivilegedAssignmentSchedule.ReadWrite.AzureADGroup",
        "PrivilegedEligibilitySchedule.ReadWrite.AzureADGroup",
        "RoleManagement.ReadWrite.Directory",
        "RoleManagementPolicy.ReadWrite.AzureADGroup",
        "RoleManagementPolicy.ReadWrite.Directory",
      ]
      roles = []
    }
    "40-hybrid-migration" = {
      plan = [
        "Application.Read.All",
        "Directory.Read.All",
        "Domain.Read.All",
        "Group.Read.All",
        "OnPremDirectorySynchronization.Read.All",
        "Policy.Read.All",
      ]
      apply = [
        "Application.ReadWrite.OwnedBy",
        "Directory.Read.All",
        "Domain.Read.All",
        "Group.ReadWrite.All",
        "OnPremDirectorySynchronization.Read.All",
        "Policy.ReadWrite.FeatureRollout",
      ]
      roles = []
    }
    "50-intune-foundation" = {
      plan = [
        "DeviceManagementApps.Read.All",
        "DeviceManagementConfiguration.Read.All",
        "DeviceManagementRBAC.Read.All",
        "DeviceManagementServiceConfig.Read.All",
        "Group.Read.All",
      ]
      apply = [
        "DeviceManagementApps.ReadWrite.All",
        "DeviceManagementConfiguration.ReadWrite.All",
        "DeviceManagementRBAC.ReadWrite.All",
        "DeviceManagementServiceConfig.ReadWrite.All",
        "Group.ReadWrite.All",
      ]
      roles = []
    }
    "60-intune-autopilot-zero-touch" = {
      plan = [
        "Application.Read.All",
        "DeviceManagementApps.Read.All",
        "DeviceManagementConfiguration.Read.All",
        "DeviceManagementServiceConfig.Read.All",
        "Group.Read.All",
      ]
      apply = [
        "Application.Read.All",
        "DeviceManagementApps.ReadWrite.All",
        "DeviceManagementConfiguration.ReadWrite.All",
        "DeviceManagementServiceConfig.ReadWrite.All",
        "Group.ReadWrite.All",
      ]
      roles = []
    }
    # Entra diagnostic settings and tenant connectors require Security Administrator.
    "70-security-operations" = {
      plan  = []
      apply = []
      roles = ["Security Administrator"]
    }
  }

  granted_stacks = setunion(["00-bootstrap"], var.enabled_stacks)

  plan_graph_roles  = toset(flatten([for s in local.granted_stacks : local.stack_permissions[s].plan]))
  apply_graph_roles = toset(flatten([for s in local.granted_stacks : local.stack_permissions[s].apply]))
  apply_dir_roles   = toset(flatten([for s in local.granted_stacks : local.stack_permissions[s].roles]))

  secops_enabled = contains(var.enabled_stacks, "70-security-operations")

  role_template_ids = { for t in data.azuread_directory_role_templates.all.role_templates : t.display_name => t.template_id }
}
