function Add-BeforeExact {
    param(
        [string]$Text,
        [string]$ExactLine,
        [string]$InsertBlock
    )
    $escaped = [regex]::Escape($ExactLine)
    $pattern = "(?m)^$escaped$"
    return [regex]::Replace($Text, $pattern, ($InsertBlock + "`r`n" + $ExactLine), 1)
}

function Build-Header {
    param(
        [int]$Module,
        [string]$Title,
        [string]$Subtitle
    )
    return @"
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

function Modernize-Lecture {
    param(
        [string]$OldFile,
        [string]$NewFile,
        [int]$Module,
        [string]$Title,
        [string]$Subtitle,
        [int]$ReviewModule,
        [bool]$NeedsSyntheticReview,
        [string]$SyntheticReviewFrame,
        [string]$LearningOutcomesFrame,
        [array]$SectionInserts,
        [string]$SummaryFrame
    )

    $raw = Get-Content -Path $OldFile -Raw
    $m = [regex]::Match($raw, '\\begin\{document\}(?<body>[\s\S]*?)\\end\{document\}')
    if (-not $m.Success) { throw "Could not find document body in $OldFile" }
    $body = $m.Groups['body'].Value.Trim()

    $titleEnd = [regex]::Match($body, '\\begin\{frame\}[\s\S]*?\\end\{frame\}')
    if (-not $titleEnd.Success) { throw "Could not find title frame in $OldFile" }
    $body = $body.Insert($titleEnd.Index + $titleEnd.Length, "`r`n`r`n% Table of contents in presentation mode only`r`n\presentationonly{`r`n\begin{frame}{Outline}`r`n\tableofcontents`r`n\end{frame}`r`n}`r`n")

    if ($NeedsSyntheticReview) {
        $body = Add-BeforeExact -Text $body -ExactLine "\begin{frame}{$LearningOutcomesFrame}" -InsertBlock @"
% =============================================================================
% REVIEW FROM PREVIOUS MODULE
% =============================================================================
\section*{Review from Module $ReviewModule}

$SyntheticReviewFrame

% =============================================================================
% LEARNING OUTCOMES
% =============================================================================
\section*{Learning Outcomes}
"@
    }
    else {
        $body = Add-BeforeExact -Text $body -ExactLine "\begin{frame}{Review: " + "" -InsertBlock ""
        $reviewRegex = '(?m)^\\begin\{frame\}\{Review:[^\r\n]*\}$'
        $body = [regex]::Replace($body, $reviewRegex, "% =============================================================================`r`n% REVIEW FROM PREVIOUS MODULE`r`n% =============================================================================`r`n\section*{Review from Module $ReviewModule}`r`n`r`n`$0", 1)
        $body = Add-BeforeExact -Text $body -ExactLine "\begin{frame}{$LearningOutcomesFrame}" -InsertBlock @"
% =============================================================================
% LEARNING OUTCOMES
% =============================================================================
\section*{Learning Outcomes}
"@
    }

    foreach ($s in $SectionInserts) {
        $block = @"
\section{$($s.Section)}
\subsection{$($s.Subsection)}

\articleonly{
$($s.Article)
}
"@
        $body = Add-BeforeExact -Text $body -ExactLine "\begin{frame}{$($s.Frame)}" -InsertBlock $block
    }

    $body = Add-BeforeExact -Text $body -ExactLine "\begin{frame}{$SummaryFrame}" -InsertBlock @"
% =============================================================================
% MODULE SUMMARY
% =============================================================================
\section*{Module Summary}
"@

    $header = Build-Header -Module $Module -Title $Title -Subtitle $Subtitle
    $final = $header + "`r`n" + $body + "`r`n`r`n\end{document}`r`n"
    Set-Content -Path $NewFile -Value $final
}

Modernize-Lecture -OldFile 'network_03_switches_interfaces_old.tex' -NewFile 'network_03_switches_interfaces.tex' -Module 3 -Title 'Network Interfaces and Switches' -Subtitle 'Network+ Module 3.0' -ReviewModule 2 -NeedsSyntheticReview $false -SyntheticReviewFrame '' -LearningOutcomesFrame 'Module Overview and Learning Outcomes' -SectionInserts @(
    @{ Frame='What is a Network Interface Card (NIC)?'; Section='Network Interface Foundations'; Subsection='NIC Fundamentals'; Article='This section introduces network interface cards and transceivers as the hardware bridge between end devices and the network. We examine capabilities, deployment contexts, and common physical-layer issues that affect reliability and performance.' },
    @{ Frame='Ethernet Frame Format'; Section='Ethernet Frames and MAC Addressing'; Subsection='Frame Structure and Addressing'; Article='This section explains how Ethernet frames carry data at Layer 2 and how MAC addressing enables local delivery decisions. Understanding frame fields and MAC semantics is essential for switch operation and troubleshooting.' },
    @{ Frame='The Evolution: Why Switches?'; Section='Switching Concepts and Forwarding'; Subsection='Hubs, Bridges, and Switches'; Article='This section compares legacy and modern Layer 2 devices and shows why switching became the dominant LAN architecture. We focus on forwarding behavior, collision domains, and MAC learning.' },
    @{ Frame='Unmanaged vs Managed Switches'; Section='Switch Interfaces and Management'; Subsection='Switch Features and Configuration'; Article='This section covers switch management models and interface configuration basics. We connect feature sets to real deployment decisions, including Layer 2 versus Layer 3 switching capabilities.' },
    @{ Frame='Link Aggregation and NIC Teaming'; Section='Advanced Switching Topics'; Subsection='Resiliency and Performance Features'; Article='This section explores advanced switching features used to improve throughput, availability, and power delivery. Topics include link aggregation, MTU considerations, STP behavior, and PoE planning.' },
    @{ Frame='Hardware Failure and Port Status Indicators'; Section='Troubleshooting Interfaces and Switches'; Subsection='Operational Diagnostics'; Article='This section presents a practical troubleshooting workflow for interface and switching problems. We interpret status indicators, command outputs, and error counters to isolate root causes quickly.' }
) -SummaryFrame 'Module 3.0 Summary'

Modernize-Lecture -OldFile 'network_04_IP_old.tex' -NewFile 'network_04_IP.tex' -Module 4 -Title 'IP Addressing and Subnetting Fundamentals' -Subtitle 'Network+ Module 4.0' -ReviewModule 3 -NeedsSyntheticReview $false -SyntheticReviewFrame '' -LearningOutcomesFrame 'Module Overview and Learning Outcomes' -SectionInserts @(
    @{ Frame='The IPv4 Datagram Header'; Section='IP Fundamentals and Address Resolution'; Subsection='IPv4 Header and Address Roles'; Article='This section introduces Layer 3 addressing and the structure of the IPv4 datagram. We also connect IP addressing to Layer 2 delivery through ARP and common traffic types such as unicast and broadcast.' },
    @{ Frame='IPv4 Address Format'; Section='Subnetting and Host Addressing'; Subsection='Address Structure and Masks'; Article='This section develops practical subnetting skills using IPv4 address structure, subnet masks, and host range calculations. These techniques are foundational for network design and troubleshooting.' },
    @{ Frame='Classful Addressing (Legacy)'; Section='Address Planning Strategies'; Subsection='Classful, CIDR, and VLSM'; Article='This section compares historical and modern address planning methods. We examine private/public ranges, reserved space, CIDR, and VLSM to support efficient and scalable network allocation.' },
    @{ Frame='ipconfig (Windows)'; Section='IP Configuration and Diagnostics'; Subsection='Host Tools and Connectivity Testing'; Article='This section focuses on practical command-line tools for viewing and troubleshooting addressing state. We use host configuration, ARP inspection, and ping methodology to validate end-to-end connectivity.' },
    @{ Frame='Why IPv6? The Problem with IPv4'; Section='IPv6 Fundamentals'; Subsection='Addressing, Types, and Transition'; Article='This section introduces IPv6 motivations, address representation, and core address types. We close with transition approaches used in mixed IPv4/IPv6 environments.' }
) -SummaryFrame 'Module 4.0 Summary: IPv4 Fundamentals'

Modernize-Lecture -OldFile 'network_05_routing_old.tex' -NewFile 'network_05_routing.tex' -Module 5 -Title 'Routing Fundamentals and Network Segmentation' -Subtitle 'Network+ Module 5.0' -ReviewModule 4 -NeedsSyntheticReview $false -SyntheticReviewFrame '' -LearningOutcomesFrame 'Module Overview and Learning Outcomes' -SectionInserts @(
    @{ Frame='The Router: Gateway Between Networks'; Section='Routing Foundations'; Subsection='Routers and Path Selection'; Article='This section establishes core routing behavior, including route selection, forwarding, and packet handling across network boundaries. It provides the conceptual model needed before configuration tasks.' },
    @{ Frame='Basic Router Configuration'; Section='Router Configuration and Tools'; Subsection='Static Routing and Diagnostics'; Article='This section applies routing concepts using foundational configuration and verification commands. We use operational tools to read routing state and trace packet paths.' },
    @{ Frame='Dynamic Routing Protocols Overview'; Section='Dynamic Routing Protocols'; Subsection='RIP, EIGRP, OSPF, and BGP'; Article='This section compares major dynamic routing protocols and how they exchange and prioritize routes. We emphasize protocol roles, strengths, and typical deployment contexts.' },
    @{ Frame='Edge Routers and Network Boundaries'; Section='Edge Services and Translation'; Subsection='NAT, PAT, and Firewalls'; Article='This section examines edge-network functions that connect private networks to external resources securely. Topics include NAT/PAT behavior, firewall placement, and DMZ design.' },
    @{ Frame='Introduction to VLANs'; Section='VLAN Segmentation and Trunking'; Subsection='VLAN Design and Security'; Article='This section explains logical segmentation with VLANs and the trunking mechanisms that carry multiple VLANs between switches. We also review native VLAN and voice VLAN considerations.' }
) -SummaryFrame 'Module 5 Summary (Part 1)'

Modernize-Lecture -OldFile 'network_06_nw_services_old.tex' -NewFile 'network_06_nw_services.tex' -Module 6 -Title 'Core Network Services and Transport Protocols' -Subtitle 'Network+ Module 6.0' -ReviewModule 5 -NeedsSyntheticReview $false -SyntheticReviewFrame '' -LearningOutcomesFrame 'Module 6 Overview' -SectionInserts @(
    @{ Frame='Transport Layer and Ports'; Section='Transport Layer Services'; Subsection='Ports, TCP, and UDP'; Article='This section reviews transport-layer communication models and port usage for application delivery. We contrast TCP reliability mechanisms with UDP efficiency and explore when each is appropriate.' },
    @{ Frame='DHCP Overview'; Section='DHCP Address Management'; Subsection='DORA and Scope Configuration'; Article='This section covers dynamic host addressing workflows, including lease assignment, options, reservations, and relay behavior. We focus on operational DHCP design and troubleshooting practices.' },
    @{ Frame='IPv6 SLAAC: Stateless Address Autoconfiguration'; Section='IPv6 Address Assignment'; Subsection='SLAAC and DHCPv6'; Article='This section introduces IPv6 client address assignment methods and their deployment trade-offs. We compare SLAAC and DHCPv6 in practical enterprise environments.' },
    @{ Frame='DNS: The Internet''s Phone Book'; Section='DNS Resolution Services'; Subsection='Hierarchy, Records, and Operations'; Article='This section explains how DNS resolves names to addresses across distributed namespace infrastructure. We examine record types, server roles, and troubleshooting techniques.' }
) -SummaryFrame 'Module 6 Summary'

$review8 = @"
\begin{frame}{Review: From Module 7 to Network Operations}
    \begin{itemize}
        \item Module 7 focused on application services, availability, and resiliency.
        \item In this module, we shift to operating live networks through documentation, monitoring, and analysis.
        \item Strong operations practices turn network design into sustained, measurable reliability.
    \end{itemize}
\end{frame}
"@

Modernize-Lecture -OldFile 'network_07_nw_app_old.tex' -NewFile 'network_07_nw_app.tex' -Module 7 -Title 'Network Applications and Service Design' -Subtitle 'Network+ Module 7.0' -ReviewModule 6 -NeedsSyntheticReview $false -SyntheticReviewFrame '' -LearningOutcomesFrame 'Module 7 Objectives: The Scheme' -SectionInserts @(
    @{ Frame='Section 7.1: Security and Time (Charlie Work)'; Section='Security and Time Services'; Subsection='TLS and Time Synchronization'; Article='This section covers foundational service controls for secure and consistent application behavior. We examine TLS trust mechanics and time synchronization services that support logs, authentication, and distributed systems.' },
    @{ Frame='Section 7.2: Web and File Services (Dennis''s Domain)'; Section='Web and File Services'; Subsection='HTTP, HTTPS, and File Access'; Article='This section explores web and file service protocols used in modern enterprise environments. We compare protocol variants, security considerations, and common deployment patterns.' },
    @{ Frame='Section 7.3: Email \& Voice (The Conspiracy)'; Section='Email and Voice Services'; Subsection='Messaging and Real-Time Communications'; Article='This section introduces core email and VoIP protocols, emphasizing workflow, reliability, and infrastructure dependencies. We connect service design choices to user experience and network requirements.' },
    @{ Frame='High Availability: "The Show Must Go On"'; Section='High Availability and Recovery'; Subsection='Resilience Planning and Redundancy'; Article='This section focuses on continuity planning through redundancy, failover, and disaster recovery targets. We compare design options using RTO/RPO, site strategies, storage, and gateway resiliency.' }
) -SummaryFrame 'Module 7 Summary: The Gang Knows Networking'

Modernize-Lecture -OldFile 'network_08_operations_monitor_old.tex' -NewFile 'network_08_operations_monitor.tex' -Module 8 -Title 'Network Operations, Monitoring, and Analysis' -Subtitle 'Network+ Module 8.0' -ReviewModule 7 -NeedsSyntheticReview $true -SyntheticReviewFrame $review8 -LearningOutcomesFrame 'Our Mission: Taming the Swamp' -SectionInserts @(
    @{ Frame='8.1 Documentation: Maps for the Kingdom'; Section='Documentation and Operational Control'; Subsection='Documentation, Inventory, and Change'; Article='This section establishes operational discipline through documentation, inventory control, and managed change practices. These processes create the baseline required for stable network operations.' },
    @{ Frame='8.2 Host Discovery: "Who Goes There?"'; Section='Discovery and Baseline Monitoring'; Subsection='Discovery Techniques and Visibility'; Article='This section introduces host and service discovery methods used to build situational awareness. We compare active and passive techniques and interpret scan output responsibly.' },
    @{ Frame='8.3 SNMP: The Royal Messengers'; Section='Telemetry and Event Monitoring'; Subsection='SNMP and Syslog Workflows'; Article='This section covers foundational monitoring telemetry using SNMP and event logging via syslog. We examine protocol operations, security considerations, and escalation workflows.' },
    @{ Frame='8.5 Traffic Analysis: NetFlow vs. Packet Capture'; Section='Traffic Analysis and QoS'; Subsection='Flow Data, Packet Capture, and Prioritization'; Article='This section analyzes traffic behavior using flow records, packet capture, and quality-of-service controls. These tools support performance tuning and incident response.' }
) -SummaryFrame 'Module 8 Review: Key Takeaways'

$review9 = @"
\begin{frame}{Review: Operations Foundations from Module 8}
    \begin{itemize}
        \item Module 8 established documentation, monitoring, and telemetry workflows.
        \item Security in Module 9 builds on that visibility to identify, prevent, and respond to threats.
        \item Effective defense requires both technical controls and disciplined operational practice.
    \end{itemize}
\end{frame}
"@

Modernize-Lecture -OldFile 'network_09_security_concepts_old.tex' -NewFile 'network_09_security_concepts.tex' -Module 9 -Title 'Security Concepts and Network Threat Defense' -Subtitle 'Network+ Module 9.0' -ReviewModule 8 -NeedsSyntheticReview $true -SyntheticReviewFrame $review9 -LearningOutcomesFrame 'Module 9 Roadmap' -SectionInserts @(
    @{ Frame='9.1 Security Terminology: The CIA Triad'; Section='Security Foundations'; Subsection='Core Principles and Controls'; Article='This section introduces fundamental security objectives, terminology, and control categories. We connect confidentiality, integrity, and availability to practical network defense decisions.' },
    @{ Frame='9.2 Threat Types and Assessment'; Section='Threats and Risk Assessment'; Subsection='DoS, Botnets, and Malware'; Article='This section surveys common threat classes and the methods used to assess their impact. We focus on attack behavior, propagation patterns, and defensive prioritization.' },
    @{ Frame='9.3 Spoofing: The Fake Return Address'; Section='Spoofing and On-Path Attacks'; Subsection='Identity and Traffic Manipulation'; Article='This section explains attacks that manipulate identity and traffic paths, including spoofing and on-path techniques. We examine how Layer 2 and Layer 3 trust assumptions can be abused.' },
    @{ Frame='9.4 Rogue Devices and Evil Twins'; Section='Rogue Services and Infrastructure Attacks'; Subsection='Rogue DHCP, DNS, and Access Points'; Article='This section covers threats introduced by unauthorized infrastructure and deceptive services. We pair each risk with practical mitigations such as snooping, segmentation, and monitoring.' },
    @{ Frame='9.5 Social Engineering: Hacking the Human'; Section='Human-Centered Threats'; Subsection='Social Engineering and Credential Attacks'; Article='This section addresses attacker techniques that target user behavior and weak authentication practices. We emphasize awareness, policy, and technical controls for layered protection.' },
    @{ Frame='Recap: Offensive vs. Defensive'; Section='Mitigation and Security Operations'; Subsection='Analysis, Defense in Depth, and Next Steps'; Article='This section consolidates offensive and defensive perspectives into actionable mitigation strategy. We close with packet analysis context, layered controls, and resources for continued learning.' }
) -SummaryFrame 'Recap: Offensive vs. Defensive'
