function Insert-Before {
    param([string]$Body,[string]$Marker,[string]$Insert)
    if ($Body.Contains($Marker)) { return $Body.Replace($Marker, $Insert + "`r`n" + $Marker) }
    return $Body
}

function Build-Header([int]$Module,[string]$Title,[string]$Subtitle) {
@"
% Select document class: uncomment one of the following
\documentclass[aspectratio=169]{beamer}  % For presentation mode
%\documentclass[11pt]{article}            % For article mode
%\usepackage{beamerarticle}               % Uncomment with article class

% =============================================================================
% COMMON PREAMBLE
% =============================================================================
\input{network_preamble.tex}

% =============================================================================
% DOCUMENT INFO
% =============================================================================
\title[Networks Module $Module.0]{$Title}
\subtitle{$Subtitle}
\author[B. Shea]{Brendan Shea, PhD}
\institute[RCTC]{Rochester Community and Technical College\\Intro to Networking}
\date{}

\begin{document}
"@
}

function Rebuild {
param(
[string]$OldFile,[string]$NewFile,[int]$Module,[string]$Title,[string]$Subtitle,
[int]$ReviewModule,[string]$ReviewFrame,[string]$LearningFrame,[array]$Sections,[string]$SummaryFrame,[string]$SyntheticReview
)
$raw = Get-Content $OldFile -Raw
$m = [regex]::Match($raw,'\\begin\{document\}(?<body>[\s\S]*?)\\end\{document\}')
$body = $m.Groups['body'].Value.Trim()
$body = [regex]::Replace($body,'\\end\{frame\}','\\end{frame}`r`n`r`n% Table of contents in presentation mode only`r`n\presentationonly{`r`n\begin{frame}{Outline}`r`n\tableofcontents`r`n\end{frame}`r`n}',1)

if ($ReviewFrame -ne '') {
$reviewBlock = "% =============================================================================`r`n% REVIEW FROM PREVIOUS MODULE`r`n% =============================================================================`r`n\section*{Review from Module $ReviewModule}`r`n"
$body = Insert-Before $body "\begin{frame}{$ReviewFrame}" $reviewBlock
$body = Insert-Before $body "\begin{frame}{$LearningFrame}" "% =============================================================================`r`n% LEARNING OUTCOMES`r`n% =============================================================================`r`n\section*{Learning Outcomes}`r`n"
} else {
$insert = "% =============================================================================`r`n% REVIEW FROM PREVIOUS MODULE`r`n% =============================================================================`r`n\section*{Review from Module $ReviewModule}`r`n`r`n$SyntheticReview`r`n`r`n% =============================================================================`r`n% LEARNING OUTCOMES`r`n% =============================================================================`r`n\section*{Learning Outcomes}`r`n"
$body = Insert-Before $body "\begin{frame}{$LearningFrame}" $insert
}

foreach($s in $Sections){
$secBlock = "\section{$($s.Section)}`r`n\subsection{$($s.Subsection)}`r`n`r`n\articleonly{`r`n$($s.Article)`r`n}`r`n"
$body = Insert-Before $body "\begin{frame}{$($s.Frame)}" $secBlock
}

$body = Insert-Before $body "\begin{frame}{$SummaryFrame}" "% =============================================================================`r`n% MODULE SUMMARY`r`n% =============================================================================`r`n\section*{Module Summary}`r`n"

$final = (Build-Header $Module $Title $Subtitle) + "`r`n" + $body + "`r`n`r`n\end{document}`r`n"
Set-Content $NewFile $final
}

Rebuild 'network_03_switches_interfaces_old.tex' 'network_03_switches_interfaces.tex' 3 'Network Interfaces and Switches' 'Network+ Module 3.0' 2 'Review: From Cables to Connections' 'Module Overview and Learning Outcomes' @(
@{Frame='What is a Network Interface Card (NIC)?';Section='Network Interface Foundations';Subsection='NIC Fundamentals';Article='This section introduces network interface cards and transceivers as the hardware bridge between endpoints and the network. It explains capability differences and common deployment tradeoffs. The goal is to connect physical interface design to reliable connectivity.'},
@{Frame='Ethernet Frame Format';Section='Ethernet Frames and MAC Addressing';Subsection='Frame Structure and Addressing';Article='This section explains how Ethernet frames are structured and delivered at Layer 2. It connects frame fields to MAC-based forwarding decisions. These concepts provide the basis for switch behavior and diagnostics.'},
@{Frame='The Evolution: Why Switches?';Section='Switching Concepts and Forwarding';Subsection='Hubs, Bridges, and Switches';Article='This section compares hubs, bridges, and switches to show how LAN performance evolved. It focuses on collision domains, learning behavior, and forwarding logic. Understanding this evolution clarifies why switching is central to modern Ethernet.'},
@{Frame='Unmanaged vs Managed Switches';Section='Switch Interfaces and Management';Subsection='Switch Features and Configuration';Article='This section covers managed versus unmanaged switching models and core interface settings. It highlights operational controls administrators use in real deployments. The material bridges conceptual switching and practical configuration.'},
@{Frame='Link Aggregation and NIC Teaming';Section='Advanced Switching Topics';Subsection='Resiliency and Performance Features';Article='This section introduces advanced Layer 2 features for capacity and resilience. Topics include link aggregation, MTU tuning, spanning tree behavior, and PoE power planning. These controls improve uptime and throughput in production networks.'},
@{Frame='Hardware Failure and Port Status Indicators';Section='Troubleshooting Interfaces and Switches';Subsection='Operational Diagnostics';Article='This section presents a structured troubleshooting approach for interface and switch issues. It uses indicators, CLI output, and error counters to isolate failure causes. The emphasis is fast diagnosis with repeatable methodology.'}
) 'Module 3.0 Summary' ''

Rebuild 'network_04_IP_old.tex' 'network_04_IP.tex' 4 'IP Addressing and Subnetting Fundamentals' 'Network+ Module 4.0' 3 'Review: From Layer 2 to Layer 3' 'Module Overview and Learning Outcomes' @(
@{Frame='The IPv4 Datagram Header';Section='IP Fundamentals and Address Resolution';Subsection='IPv4 Header and Address Roles';Article='This section introduces IPv4 packet structure and how Layer 3 addressing enables end-to-end delivery. It also ties ARP to local next-hop resolution. Together these concepts explain how packets move beyond a single LAN.'},
@{Frame='IPv4 Address Format';Section='Subnetting and Host Addressing';Subsection='Address Structure and Masks';Article='This section builds subnetting fundamentals from address format, masks, and host ranges. It emphasizes deterministic calculation techniques for design and support work. Mastery here is essential for routing and segmentation tasks.'},
@{Frame='Classful Addressing (Legacy)';Section='Address Planning Strategies';Subsection='Classful, CIDR, and VLSM';Article='This section compares legacy classful allocation with modern CIDR and VLSM planning. It includes public, private, and reserved ranges. The objective is efficient, scalable address assignment.'},
@{Frame='ipconfig (Windows)';Section='IP Configuration and Diagnostics';Subsection='Host Tools and Connectivity Testing';Article='This section applies IP theory using practical command-line troubleshooting tools. It reviews host configuration, ARP inspection, and connectivity testing workflows. The focus is actionable diagnostics for common field issues.'},
@{Frame='Why IPv6? The Problem with IPv4';Section='IPv6 Fundamentals';Subsection='Addressing, Types, and Transition';Article='This section introduces IPv6 motivation, format, and address types. It also covers migration and coexistence approaches with IPv4. The goal is readiness for dual-stack environments.'}
) 'Module 4.0 Summary: IPv4 Fundamentals' ''

Rebuild 'network_05_routing_old.tex' 'network_05_routing.tex' 5 'Routing Fundamentals and Network Segmentation' 'Network+ Module 5.0' 4 'Review: From IP Addressing to Routing' 'Module Overview and Learning Outcomes' @(
@{Frame='The Router: Gateway Between Networks';Section='Routing Foundations';Subsection='Routers and Path Selection';Article='This section establishes the routing model used to move packets across network boundaries. It explains route lookup, path choice, and forwarding outcomes. These principles anchor all later protocol and configuration topics.'},
@{Frame='Basic Router Configuration';Section='Router Configuration and Tools';Subsection='Static Routing and Diagnostics';Article='This section applies routing principles through baseline configuration and verification commands. It includes tools for interpreting route state and packet paths. The aim is operational confidence with foundational workflows.'},
@{Frame='Dynamic Routing Protocols Overview';Section='Dynamic Routing Protocols';Subsection='RIP, EIGRP, OSPF, and BGP';Article='This section compares dynamic routing protocols by mechanism, scale, and use case. It shows how route information is exchanged and preferred. The content prepares students to select protocols for given scenarios.'},
@{Frame='Edge Routers and Network Boundaries';Section='Edge Services and Translation';Subsection='NAT, PAT, and Firewalls';Article='This section examines border-network services that connect internal networks to external resources. It covers NAT/PAT behavior, perimeter firewall placement, and DMZ concepts. These controls are central to secure internet access.'},
@{Frame='Introduction to VLANs';Section='VLAN Segmentation and Trunking';Subsection='VLAN Design and Security';Article='This section introduces logical segmentation with VLANs and inter-switch trunking. It ties tagging behavior to operational and security practices. The goal is improved isolation and manageability in switched environments.'}
) 'Module 5 Summary (Part 1)' ''

Rebuild 'network_06_nw_services_old.tex' 'network_06_nw_services.tex' 6 'Core Network Services and Transport Protocols' 'Network+ Module 6.0' 5 'Review: Building on Module 5' 'Module 6 Overview' @(
@{Frame='Transport Layer and Ports';Section='Transport Layer Services';Subsection='Ports, TCP, and UDP';Article='This section explains transport-layer communication and service multiplexing with ports. It compares TCP reliability with UDP efficiency across application types. The focus is selecting the right transport behavior for the workload.'},
@{Frame='DHCP Overview';Section='DHCP Address Management';Subsection='DORA and Scope Configuration';Article='This section covers dynamic address assignment design and operation. It examines leases, scopes, options, relay behavior, and exception handling. The content supports real-world deployment and troubleshooting.'},
@{Frame='IPv6 SLAAC: Stateless Address Autoconfiguration';Section='IPv6 Address Assignment';Subsection='SLAAC and DHCPv6';Article='This section compares IPv6 client addressing models, including SLAAC and DHCPv6. It highlights operational tradeoffs and control points. The objective is accurate method selection for enterprise networks.'},
@{Frame='DNS: The Internet''s Phone Book';Section='DNS Resolution Services';Subsection='Hierarchy, Records, and Operations';Article='This section explains DNS architecture, record usage, and resolution behavior. It connects namespace design to dependable client access. Troubleshooting techniques reinforce service reliability practices.'}
) 'Module 6 Summary' ''

Rebuild 'network_07_nw_app_old.tex' 'network_07_nw_app.tex' 7 'Network Applications and Service Design' 'Network+ Module 7.0' 6 'Review: The Gang Recaps Module 6' 'Module 7 Objectives: The Scheme' @(
@{Frame='Section 7.1: Security and Time (Charlie Work)';Section='Security and Time Services';Subsection='TLS and Time Synchronization';Article='This section introduces foundational services for secure communication and consistent timekeeping. It covers TLS trust mechanics and time protocols that support authentication and observability. These capabilities underpin dependable application operations.'},
@{Frame='Section 7.2: Web and File Services (Dennis''s Domain)';Section='Web and File Services';Subsection='HTTP, HTTPS, and File Access';Article='This section surveys core web and file-transfer services used in enterprise networks. It compares protocol variants and security implications. The goal is selecting service patterns that balance performance and protection.'},
@{Frame='Section 7.3: Email \& Voice (The Conspiracy)';Section='Email and Voice Services';Subsection='Messaging and Real-Time Communications';Article='This section explains protocol workflows for email and voice communications. It emphasizes reliability, latency sensitivity, and infrastructure dependencies. The content links service behavior to user experience outcomes.'},
@{Frame='High Availability: "The Show Must Go On"';Section='High Availability and Recovery';Subsection='Resilience Planning and Redundancy';Article='This section covers continuity strategies including redundancy, failover, and disaster recovery objectives. It compares storage, gateway, and site options for resilience. The outcome is practical decision-making for availability targets.'}
) 'Module 7 Summary: The Gang Knows Networking' ''

$review8 = '\begin{frame}{Review: From Module 7 to Network Operations}`r`n    \begin{itemize}`r`n        \item Module 7 focused on application services, availability, and resilience design.`r`n        \item Module 8 shifts to operating and observing production networks.`r`n        \item Strong monitoring and documentation make reliability measurable and repeatable.`r`n    \end{itemize}`r`n\end{frame}'

Rebuild 'network_08_operations_monitor_old.tex' 'network_08_operations_monitor.tex' 8 'Network Operations, Monitoring, and Analysis' 'Network+ Module 8.0' 7 '' 'Our Mission: Taming the Swamp' @(
@{Frame='8.1 Documentation: Maps for the Kingdom';Section='Documentation and Operational Control';Subsection='Documentation, Inventory, and Change';Article='This section defines the operational records and governance practices needed to run networks predictably. It covers inventory accuracy, backup discipline, and change control. These practices reduce outage risk and speed recovery.'},
@{Frame='8.2 Host Discovery: "Who Goes There?"';Section='Discovery and Baseline Monitoring';Subsection='Discovery Techniques and Visibility';Article='This section introduces methods for discovering devices and services on active networks. It contrasts active and passive approaches and interprets scan output. The objective is accurate visibility without unnecessary disruption.'},
@{Frame='8.3 SNMP: The Royal Messengers';Section='Telemetry and Event Monitoring';Subsection='SNMP and Syslog Workflows';Article='This section explains telemetry and event collection with SNMP and syslog. It addresses operations, versions, and secure deployment patterns. These mechanisms provide the core signal feed for monitoring platforms.'},
@{Frame='8.5 Traffic Analysis: NetFlow vs. Packet Capture';Section='Traffic Analysis and QoS';Subsection='Flow Data, Packet Capture, and Prioritization';Article='This section analyzes traffic behavior with flow records and packet captures, then applies QoS controls. It ties evidence to tuning decisions and incident workflows. The result is better performance and user experience under load.'}
) 'Module 8 Review: Key Takeaways' $review8

$review9 = '\begin{frame}{Review: Operations Foundations from Module 8}`r`n    \begin{itemize}`r`n        \item Module 8 established documentation, telemetry, and monitoring workflows.`r`n        \item Module 9 builds on that visibility to identify and mitigate security threats.`r`n        \item Effective defense combines technical controls with disciplined operations.`r`n    \end{itemize}`r`n\end{frame}'

Rebuild 'network_09_security_concepts_old.tex' 'network_09_security_concepts.tex' 9 'Security Concepts and Network Threat Defense' 'Network+ Module 9.0' 8 '' 'Module 9 Roadmap' @(
@{Frame='9.1 Security Terminology: The CIA Triad';Section='Security Foundations';Subsection='Core Principles and Controls';Article='This section establishes the core language and objectives of network security. It links foundational principles to practical defensive controls. The aim is consistent reasoning about risk and protection.'},
@{Frame='9.2 Threat Types and Assessment';Section='Threats and Risk Assessment';Subsection='DoS, Botnets, and Malware';Article='This section surveys major threat categories and assessment approaches. It emphasizes behavior patterns, likely impact, and prioritization. These concepts support structured defensive planning.'},
@{Frame='9.3 Spoofing: The Fake Return Address';Section='Spoofing and On-Path Attacks';Subsection='Identity and Traffic Manipulation';Article='This section examines attacks that impersonate identities or alter traffic paths. It shows how trust assumptions are abused across layers. Mitigation starts with understanding attack mechanics.'},
@{Frame='9.4 Rogue Devices and Evil Twins';Section='Rogue Services and Infrastructure Attacks';Subsection='Rogue DHCP, DNS, and Access Points';Article='This section covers unauthorized infrastructure and deceptive services that disrupt or intercept traffic. It pairs each threat with practical network controls. The focus is prevention and rapid detection.'},
@{Frame='9.5 Social Engineering: Hacking the Human';Section='Human-Centered Threats';Subsection='Social Engineering and Credential Attacks';Article='This section addresses security failures driven by user manipulation and weak credential hygiene. It combines awareness patterns with technical safeguards. Defense requires both culture and control.'},
@{Frame='Recap: Offensive vs. Defensive';Section='Mitigation and Security Operations';Subsection='Analysis, Defense in Depth, and Next Steps';Article='This section consolidates attack and defense perspectives into an operational mitigation model. It reinforces layered security and evidence-based response. The closing resources support continued skill development.'}
) 'Recap: Offensive vs. Defensive' $review9
