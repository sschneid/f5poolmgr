# iControlTypeCast.pm
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# $Id: iControlTypeCast.pm,v 1.1.1.1 2008/07/03 16:00:57 sschneid Exp $

package iControlTypeCast;

require SOAP::Lite;

my $urnMap;

sub BEGIN {
    $urnMap = {
        "{urn:iControl}Common.ArmedState" => 1,
        "{urn:iControl}Common.AuthenticationMethod" => 1,
        "{urn:iControl}Common.AvailabilityStatus" => 1,
        "{urn:iControl}Common.DaemonStatus" => 1,
        "{urn:iControl}Common.EnabledState" => 1,
        "{urn:iControl}Common.EnabledStatus" => 1,
        "{urn:iControl}Common.FileChainType" => 1,
        "{urn:iControl}Common.HAAction" => 1,
        "{urn:iControl}Common.IPHostType" => 1,
        "{urn:iControl}Common.ProtocolType" => 1,
        "{urn:iControl}Common.StatisticType" => 1,
        "{urn:iControl}GlobalLB.AddressType" => 1,
        "{urn:iControl}GlobalLB.AutoConfigurationState" => 1,
        "{urn:iControl}GlobalLB.AvailabilityDependency" => 1,
        "{urn:iControl}GlobalLB.LBMethod" => 1,
        "{urn:iControl}GlobalLB.LDNSProbeProtocol" => 1,
        "{urn:iControl}GlobalLB.LinkWeightType" => 1,
        "{urn:iControl}GlobalLB.MetricLimitType" => 1,
        "{urn:iControl}GlobalLB.MonitorAssociationRemovalRule" => 1,
        "{urn:iControl}GlobalLB.MonitorInstanceStateType" => 1,
        "{urn:iControl}GlobalLB.MonitorRuleType" => 1,
        "{urn:iControl}GlobalLB.RegionDBType" => 1,
        "{urn:iControl}GlobalLB.RegionType" => 1,
        "{urn:iControl}GlobalLB.ServerType" => 1,
        "{urn:iControl}GlobalLB.Application.ApplicationObjectType" => 1,
        "{urn:iControl}GlobalLB.Monitor.IntPropertyType" => 1,
        "{urn:iControl}GlobalLB.Monitor.StrPropertyType" => 1,
        "{urn:iControl}GlobalLB.Monitor.TemplateType" => 1,
        "{urn:iControl}LocalLB.AddressType" => 1,
        "{urn:iControl}LocalLB.AuthenticationMethod" => 1,
        "{urn:iControl}LocalLB.AvailabilityStatus" => 1,
        "{urn:iControl}LocalLB.ClientSSLCertificateMode" => 1,
        "{urn:iControl}LocalLB.ClonePoolType" => 1,
        "{urn:iControl}LocalLB.CompressionMethod" => 1,
        "{urn:iControl}LocalLB.CookiePersistenceMethod" => 1,
        "{urn:iControl}LocalLB.CredentialSource" => 1,
        "{urn:iControl}LocalLB.EnabledStatus" => 1,
        "{urn:iControl}LocalLB.HardwareAccelerationMode" => 1,
        "{urn:iControl}LocalLB.HttpChunkMode" => 1,
        "{urn:iControl}LocalLB.HttpCompressionMode" => 1,
        "{urn:iControl}LocalLB.HttpRedirectRewriteMode" => 1,
        "{urn:iControl}LocalLB.LBMethod" => 1,
        "{urn:iControl}LocalLB.MonitorAssociationRemovalRule" => 1,
        "{urn:iControl}LocalLB.MonitorInstanceStateType" => 1,
        "{urn:iControl}LocalLB.MonitorRuleType" => 1,
        "{urn:iControl}LocalLB.MonitorStatus" => 1,
        "{urn:iControl}LocalLB.PersistenceMode" => 1,
        "{urn:iControl}LocalLB.ProfileContextType" => 1,
        "{urn:iControl}LocalLB.ProfileMode" => 1,
        "{urn:iControl}LocalLB.ProfileType" => 1,
        "{urn:iControl}LocalLB.RamCacheCacheControlMode" => 1,
        "{urn:iControl}LocalLB.RtspProxyType" => 1,
        "{urn:iControl}LocalLB.SSLOption" => 1,
        "{urn:iControl}LocalLB.ServerSSLCertificateMode" => 1,
        "{urn:iControl}LocalLB.ServiceDownAction" => 1,
        "{urn:iControl}LocalLB.SessionStatus" => 1,
        "{urn:iControl}LocalLB.SnatType" => 1,
        "{urn:iControl}LocalLB.TCPCongestionControlMode" => 1,
        "{urn:iControl}LocalLB.TCPOptionMode" => 1,
        "{urn:iControl}LocalLB.UncleanShutdownMode" => 1,
        "{urn:iControl}LocalLB.VirtualAddressStatusDependency" => 1,
        "{urn:iControl}LocalLB.Class.ClassType" => 1,
        "{urn:iControl}LocalLB.Class.FileFormatType" => 1,
        "{urn:iControl}LocalLB.Class.FileModeType" => 1,
        "{urn:iControl}LocalLB.Monitor.IntPropertyType" => 1,
        "{urn:iControl}LocalLB.Monitor.StrPropertyType" => 1,
        "{urn:iControl}LocalLB.Monitor.TemplateType" => 1,
        "{urn:iControl}LocalLB.ProfileUserStatistic.UserStatisticKey" => 1,
        "{urn:iControl}LocalLB.RAMCacheInformation.RAMCacheVaryType" => 1,
        "{urn:iControl}LocalLB.RateClass.DirectionType" => 1,
        "{urn:iControl}LocalLB.RateClass.QueueType" => 1,
        "{urn:iControl}LocalLB.RateClass.UnitType" => 1,
        "{urn:iControl}LocalLB.VirtualServer.VirtualServerCMPEnableMode" => 1,
        "{urn:iControl}LocalLB.VirtualServer.VirtualServerType" => 1,
        "{urn:iControl}Management.DebugLevel" => 1,
        "{urn:iControl}Management.LDAPPasswordEncodingOption" => 1,
        "{urn:iControl}Management.LDAPSSLOption" => 1,
        "{urn:iControl}Management.LDAPSearchMethod" => 1,
        "{urn:iControl}Management.LDAPSearchScope" => 1,
        "{urn:iControl}Management.OCSPDigestMethod" => 1,
        "{urn:iControl}Management.ZoneType" => 1,
        "{urn:iControl}Management.EventNotification.EventDataType" => 1,
        "{urn:iControl}Management.EventSubscription.AuthenticationMode" => 1,
        "{urn:iControl}Management.EventSubscription.EventType" => 1,
        "{urn:iControl}Management.EventSubscription.ObjectType" => 1,
        "{urn:iControl}Management.EventSubscription.SubscriptionStatusCode" => 1,
        "{urn:iControl}Management.KeyCertificate.CertificateType" => 1,
        "{urn:iControl}Management.KeyCertificate.KeyType" => 1,
        "{urn:iControl}Management.KeyCertificate.ManagementModeType" => 1,
        "{urn:iControl}Management.KeyCertificate.SecurityType" => 1,
        "{urn:iControl}Management.KeyCertificate.ValidityType" => 1,
        "{urn:iControl}Management.SNMPConfiguration.AuthType" => 1,
        "{urn:iControl}Management.SNMPConfiguration.DiskCheckType" => 1,
        "{urn:iControl}Management.SNMPConfiguration.LevelType" => 1,
        "{urn:iControl}Management.SNMPConfiguration.ModelType" => 1,
        "{urn:iControl}Management.SNMPConfiguration.PrefixType" => 1,
        "{urn:iControl}Management.SNMPConfiguration.PrivacyProtocolType" => 1,
        "{urn:iControl}Management.SNMPConfiguration.SinkType" => 1,
        "{urn:iControl}Management.SNMPConfiguration.TransportType" => 1,
        "{urn:iControl}Management.SNMPConfiguration.ViewType" => 1,
        "{urn:iControl}Management.UserManagement.UserRole" => 1,
        "{urn:iControl}Networking.FilterAction" => 1,
        "{urn:iControl}Networking.FlowControlType" => 1,
        "{urn:iControl}Networking.LearningMode" => 1,
        "{urn:iControl}Networking.MediaStatus" => 1,
        "{urn:iControl}Networking.MemberTagType" => 1,
        "{urn:iControl}Networking.MemberType" => 1,
        "{urn:iControl}Networking.PhyMasterSlaveMode" => 1,
        "{urn:iControl}Networking.RouteEntryType" => 1,
        "{urn:iControl}Networking.STPLinkType" => 1,
        "{urn:iControl}Networking.STPModeType" => 1,
        "{urn:iControl}Networking.STPRoleType" => 1,
        "{urn:iControl}Networking.STPStateType" => 1,
        "{urn:iControl}Networking.ARP.NDPState" => 1,
        "{urn:iControl}Networking.Interfaces.MediaType" => 1,
        "{urn:iControl}Networking.STPInstance.PathCostType" => 1,
        "{urn:iControl}Networking.SelfIPPortLockdown.AllowMode" => 1,
        "{urn:iControl}Networking.Trunk.DistributionHashOption" => 1,
        "{urn:iControl}Networking.Trunk.LACPTimeoutOption" => 1,
        "{urn:iControl}Networking.Trunk.LinkSelectionPolicy" => 1,
        "{urn:iControl}Networking.VLANGroup.VLANGroupTransparency" => 1,
        "{urn:iControl}System.CPUMetricType" => 1,
        "{urn:iControl}System.FanMetricType" => 1,
        "{urn:iControl}System.PSMetricType" => 1,
        "{urn:iControl}System.TemperatureMetricType" => 1,
        "{urn:iControl}System.ConfigSync.ConfigExcludeComponent" => 1,
        "{urn:iControl}System.ConfigSync.ConfigIncludeComponent" => 1,
        "{urn:iControl}System.ConfigSync.LoadMode" => 1,
        "{urn:iControl}System.ConfigSync.SaveMode" => 1,
        "{urn:iControl}System.ConfigSync.SyncMode" => 1,
        "{urn:iControl}System.Failover.FailoverMode" => 1,
        "{urn:iControl}System.Failover.FailoverState" => 1,
        "{urn:iControl}System.Services.ServiceAction" => 1,
        "{urn:iControl}System.Services.ServiceStatusType" => 1,
        "{urn:iControl}System.Services.ServiceType" => 1,
        "{urn:iControl}System.Statistics.GtmIQueryState" => 1,
        "{urn:iControl}System.Statistics.GtmPathStatisticObjectType" => 1,
    }
}

sub END {}

sub SOAP::Deserializer::typecast {
    my ( $self, $value, $name, $attrs, $children, $type ) = @_;

    my $retval = undef;

    if ( 1 == $urnMap->{$type} ) { $retval = $value; }

    return $retval;
}

1;
