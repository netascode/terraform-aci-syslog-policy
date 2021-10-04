resource "aci_rest" "syslogGroup" {
  dn         = "uni/fabric/slgroup-${var.name}"
  class_name = "syslogGroup"
  content = {
    name                = var.name
    descr               = var.description
    format              = var.format
    includeMilliSeconds = var.show_millisecond == true ? "yes" : "no"
  }
}

resource "aci_rest" "syslogRemoteDest" {
  for_each   = { for dest in var.destinations : dest.hostname_ip => dest }
  dn         = "${aci_rest.syslogGroup.id}/rdst-${each.value.hostname_ip}"
  class_name = "syslogRemoteDest"
  content = {
    host               = each.value.hostname_ip
    port               = each.value.port != null ? each.value.port : 514
    adminState         = each.value.admin_state == false ? "disabled" : "enabled"
    format             = each.value.format != null ? each.value.format : "aci"
    forwardingFacility = each.value.facility != null ? each.value.facility : "local7"
    severity           = each.value.severity != null ? each.value.severity : "warnings"
  }
}

resource "aci_rest" "fileRsARemoteHostToEpg" {
  for_each   = { for dest in var.destinations : dest.hostname_ip => dest if dest.mgmt_epg_name != null }
  dn         = "${aci_rest.syslogRemoteDest[each.value.hostname_ip].id}/rsARemoteHostToEpg"
  class_name = "fileRsARemoteHostToEpg"
  content = {
    tDn = each.value.mgmt_epg_type == "oob" ? "uni/tn-mgmt/mgmtp-default/oob-${each.value.mgmt_epg_name}" : "uni/tn-mgmt/mgmtp-default/inb-${each.value.mgmt_epg_name}"
  }
}

resource "aci_rest" "syslogProf" {
  dn         = "${aci_rest.syslogGroup.id}/prof"
  class_name = "syslogProf"
  content = {
    adminState = var.admin_state == true ? "enabled" : "disabled"
    name       = "syslog"
  }
}

resource "aci_rest" "syslogFile" {
  dn         = "${aci_rest.syslogGroup.id}/file"
  class_name = "syslogFile"
  content = {
    adminState = var.local_admin_state == true ? "enabled" : "disabled"
    format     = var.format
    severity   = var.local_severity
  }
}

resource "aci_rest" "syslogConsole" {
  dn         = "${aci_rest.syslogGroup.id}/console"
  class_name = "syslogConsole"
  content = {
    adminState = var.console_admin_state == true ? "enabled" : "disabled"
    format     = var.format
    severity   = var.console_severity
  }
}
