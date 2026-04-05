# Chapter Conversion Guidelines: LaTeX → HTML

> **Purpose:** This document provides detailed instructions for converting the LaTeX/Beamer
> source files in this repository into clean, semantic HTML chapters.  
> It is designed to be used as a prompt/reference by an LLM performing the conversion.

---

## Table of Contents

1. [Project Context](#1-project-context)
2. [Input / Output Overview](#2-input--output-overview)
3. [HTML Page Template](#3-html-page-template)
4. [Section & Heading Mapping](#4-section--heading-mapping)
5. [LaTeX Command Reference](#5-latex-command-reference)
6. [Diagrams: TikZ → Mermaid](#6-diagrams-tikz--mermaid)
7. [Tables](#7-tables)
8. [Code & CLI Examples](#8-code--cli-examples)
9. [Callout Boxes](#9-callout-boxes)
10. [Learning Outcomes & Review Sections](#10-learning-outcomes--review-sections)
11. [Images](#11-images)
12. [Navigation & Sidebar](#12-navigation--sidebar)
13. [Accessibility](#13-accessibility)
14. [Quality Checklist](#14-quality-checklist)
15. [Module Registry](#15-module-registry)

---

## 1. Project Context

This is a CompTIA Network+ aligned introductory networking course with 11 modules. Each
module exists as a **LaTeX Beamer** presentation (`.tex`) that serves as the single source
of truth. The HTML chapters are **prose-style articles** derived from that content — they
should read like a textbook chapter, not a slide deck.

- **Course:** COMP 1080, Introduction to Networking  
- **Author:** Brendan Shea, PhD — Rochester Community and Technical College  
- **License:** CC-BY-NC 4.0  

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Use **Mermaid.js** for all diagrams | Replaces TikZ; text-based, renderable in browser, easy to maintain |
| **No build toolchain** for HTML | Each chapter is hand-authored (via LLM) standalone HTML |
| Shared CSS in `HTML/css/lectures.css` | Single stylesheet; chapters reference it via relative path |
| Prose-first content | Bullet-point slides are expanded into flowing paragraphs with key terms highlighted |

---

## 2. Input / Output Overview

### Input (per module)

| File | Description |
|------|-------------|
| `network_XX_name.tex` | The Beamer source file |
| `network_preamble.tex` | Shared LaTeX preamble (colours, TikZ styles, custom commands) |

### Output (per module)

| File | Location |
|------|----------|
| `index.html` | `HTML/network_XX_name/index.html` |

The HTML file must:
- Link to `../css/lectures.css` for styling
- Load Mermaid.js from CDN for diagrams
- Be fully self-contained (no other build step required)

---

## 3. HTML Page Template

Every chapter HTML file should follow this skeleton:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Module X: [Title] — Introduction to Networking">
    <meta name="author" content="Brendan Shea">
    <title>Module X: [Title] — Introduction to Networking</title>
    <link rel="stylesheet" href="../css/lectures.css">

    <!-- Mermaid.js for diagrams -->
    <script type="module">
        import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';
        mermaid.initialize({
            startOnLoad: true,
            theme: 'base',
            themeVariables: {
                primaryColor:       '#e8f1fb',
                primaryBorderColor: '#004a88',
                primaryTextColor:   '#1f2a37',
                lineColor:          '#0b5cab',
                secondaryColor:     '#fff7e0',
                tertiaryColor:      '#f0fdf4'
            }
        });
    </script>
</head>
<body>
<div class="page-wrapper">

    <!-- Sidebar / Table of Contents -->
    <aside class="sidebar">
        <a href="../../index.html" class="back-link">← All Modules</a>
        <nav>
            <!-- Auto-generated or manually listed section links -->
            <a href="#section-id" class="toc-h2">Section Title</a>
            <a href="#subsection-id" class="toc-h3">Subsection Title</a>
            <!-- ... -->
        </nav>
    </aside>

    <!-- Main Content -->
    <main class="content">
        <header class="chapter-header">
            <span class="module-label">Module X</span>
            <h1>[Chapter Title]</h1>
            <p class="subtitle">[Subtitle from \subtitle{}]</p>
        </header>

        <!-- CONTENT SECTIONS GO HERE -->

        <!-- Chapter Footer -->
        <footer class="chapter-footer">
            <p>Introduction to Networking &copy; 2025 Brendan Shea &mdash;
               Licensed under CC-BY-NC 4.0</p>
            <nav class="chapter-nav">
                <a href="../network_XX_prev/index.html">&larr; Previous: [Title]</a>
                <a href="../network_XX_next/index.html">Next: [Title] &rarr;</a>
            </nav>
        </footer>
    </main>
</div>
</body>
</html>
```

---

## 4. Section & Heading Mapping

| LaTeX | HTML | Notes |
|-------|------|-------|
| `\section{Title}` | `<h2 id="slug">Title</h2>` | Primary content sections |
| `\subsection{Title}` | `<h3 id="slug">Title</h3>` | Sub-sections |
| `\sectionslide{Title}` | `<div class="section-divider"><h2>Title</h2></div>` | Visual separator between major sections |
| `\begin{frame}{Title}` | *(content integrated into surrounding section)* | Frames are NOT 1:1 mapped; merge related frames into a coherent section |

### ID Slugs

Generate `id` values by lowercasing the title, replacing spaces with hyphens, and stripping
special characters. Example: `"What is a Network?"` → `id="what-is-a-network"`.

### Important: Frames ≠ Sections

Beamer frames are **slide-sized chunks**. When converting, you must:
1. **Merge** related frames from the same `\section` into flowing prose paragraphs.
2. **Expand** bullet points into complete sentences/paragraphs.
3. Keep the same logical structure but write as a textbook, not a slide deck.

---

## 5. LaTeX Command Reference

This table maps the custom LaTeX commands (defined in `network_preamble.tex`) to HTML:

| LaTeX Command | HTML Output | CSS Class |
|---------------|-------------|-----------|
| `\keyterm{term}` | `<strong class="key-term">term</strong>` | `.key-term` |
| `\textbf{text}` | `<strong>text</strong>` | — |
| `\textit{text}` | `<em>text</em>` | — |
| `\texttt{text}` | `<code>text</code>` | — |
| `\href{url}{text}` | `<a href="url">text</a>` | — |
| `\emph{text}` | `<em>text</em>` | — |
| `\articleonly{text}` | Include the text | This content is specifically for the article/HTML version |
| `\presentationonly{...}` | **Omit entirely** | Presentation-only content (e.g. `\tableofcontents`) |
| `\faIcon{name}` | Omit or use emoji/text equivalent | FontAwesome icons don't carry over |

### Environments

| LaTeX Environment | HTML Output | CSS Class |
|-------------------|-------------|-----------|
| `\begin{itemize}...\end{itemize}` | `<ul>...</ul>` | — |
| `\begin{enumerate}...\end{enumerate}` | `<ol>...</ol>` | — |
| `\begin{block}{Title}...\end{block}` | `<div class="callout callout-info"><div class="callout-title">Title</div>...</div>` | `.callout-info` |
| `\begin{alertblock}{Title}...` | `<div class="callout callout-warning"><div class="callout-title">Title</div>...</div>` | `.callout-warning` |
| `\begin{exampleblock}{Title}...` | `<div class="callout callout-success"><div class="callout-title">Title</div>...</div>` | `.callout-success` |
| `\begin{casestudy}...` | `<div class="callout case-study"><div class="callout-title">Case Study</div>...</div>` | `.case-study` |
| `\begin{casesolution}...` | `<div class="callout case-solution"><div class="callout-title">Solution</div>...</div>` | `.case-solution` |
| `\begin{tabular}...` | `<table>...</table>` | See [Tables](#7-tables) |
| `\begin{columns}...\end{columns}` | Integrate into flowing prose | Don't replicate Beamer column layout |

---

## 6. Diagrams: TikZ → Mermaid

**All TikZ diagrams must be rewritten as Mermaid diagrams.** Do not attempt to include SVGs
or rendered TikZ output.

### Mermaid Wrapper

```html
<div class="diagram-container">
    <pre class="mermaid">
        graph LR
            A[PC] -->|Ethernet| B[Switch]
            B -->|Fiber| C[Router]
            C -->|WAN| D((Internet))
    </pre>
    <p class="diagram-caption">Figure 1: Simple network topology showing PC to Internet path.</p>
</div>
```

### TikZ → Mermaid Translation Guide

| TikZ Pattern | Mermaid Equivalent |
|--------------|--------------------|
| `\node[pc] (pc1) {...}` | `PC1[PC]` node in graph |
| `\node[router] (r1) {...}` | `R1{Router}` (diamond or hexagon) |
| `\node[switch] (s1) {...}` | `S1[Switch]` |
| `\node[cloud] (c1) {...}` | `C1((Internet))` (circle) |
| `\node[server] (srv) {...}` | `SRV[(Server)]` (cylinder) |
| `\node[firewall] (fw) {...}` | `FW[\Firewall/]` (trapezoid) |
| `\draw[ethernet] (a) -- (b)` | `A -->|Ethernet| B` |
| `\draw[wireless] (a) -- (b)` | `A -.->|Wireless| B` (dotted) |
| `\draw[wan] (a) -- (b)` | `A ==>|WAN| B` (thick line) |
| `\draw[fiber] (a) -- (b)` | `A -->|Fiber| B` |

### Common Diagram Types and Recommended Mermaid Chart Type

| Diagram Purpose | Mermaid Type | Example |
|----------------|--------------|---------|
| Network topology | `graph LR` or `graph TD` | Devices connected by links |
| OSI model layers | `graph TD` (top-down) | Stacked layer boxes |
| Process / protocol flow | `sequenceDiagram` | TCP handshake, DNS resolution |
| Decision tree (troubleshooting) | `graph TD` with diamonds | Troubleshooting flowchart |
| Packet encapsulation | `graph LR` with nested labels | Headers wrapping data |
| Comparison / classification | `graph TD` or use an HTML table | Better as a table in many cases |
| State machine | `stateDiagram-v2` | Port states (STP), etc. |

### Mermaid Style Tips

- Prefer `graph LR` (left-to-right) for network topologies — it reads naturally.
- Use `graph TD` (top-down) for hierarchical structures like the OSI model or tree topologies.
- Keep diagram text **short** — move detailed explanations to the caption or surrounding prose.
- If a TikZ diagram is purely decorative (e.g., the title slide illustration), **omit it** or
  simplify to a small representative diagram.
- For complex diagrams with many nodes, break them into **multiple smaller Mermaid diagrams**
  with explanatory text between them rather than one massive diagram.

---

## 7. Tables

Convert LaTeX `tabular` environments to HTML tables directly.

```html
<table>
    <thead>
        <tr>
            <th>Header 1</th>
            <th>Header 2</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>Cell 1</td>
            <td>Cell 2</td>
        </tr>
    </tbody>
</table>
```

- Always use `<thead>` and `<tbody>`.
- For wide tables, the CSS will handle horizontal overflow.
- If the LaTeX uses `\multicolumn` or `\multirow`, use `colspan` / `rowspan` attributes.

---

## 8. Code & CLI Examples

Use `<pre><code>` blocks for command-line examples, IP configurations, etc.:

```html
<pre><code>C:\> ping 192.168.1.1

Pinging 192.168.1.1 with 32 bytes of data:
Reply from 192.168.1.1: bytes=32 time=1ms TTL=64</code></pre>
```

For inline commands or terms in prose, use `<code>`:

```html
<p>Use the <code>ipconfig /all</code> command to view detailed adapter information.</p>
```

---

## 9. Callout Boxes

Use callout boxes to highlight important information, warnings, and tips:

```html
<!-- Info callout (general information, tips) -->
<div class="callout callout-info">
    <div class="callout-title">Key Concept</div>
    <p>The OSI model separates networking into seven distinct layers...</p>
</div>

<!-- Warning callout (common mistakes, exam tips) -->
<div class="callout callout-warning">
    <div class="callout-title">Exam Tip</div>
    <p>Remember that Layer 1 issues must be resolved before troubleshooting higher layers.</p>
</div>

<!-- Danger callout (security warnings) -->
<div class="callout callout-danger">
    <div class="callout-title">Security Warning</div>
    <p>Never transmit passwords over unencrypted protocols like Telnet or HTTP.</p>
</div>

<!-- Case Study -->
<div class="callout case-study">
    <div class="callout-title">Case Study</div>
    <p>A small business reports intermittent connectivity issues...</p>
</div>

<!-- Case Solution -->
<div class="callout case-solution">
    <div class="callout-title">Solution</div>
    <p>The root cause was a duplex mismatch between...</p>
</div>
```

### When to Use Callouts

- **`callout-info`**: Key concepts, definitions, tips, and "good to know" info — maps from `\begin{block}`.
- **`callout-warning`**: Exam tips, common mistakes, and important caveats — maps from `\begin{alertblock}`.
- **`callout-success`**: Best practices, confirmations, working examples — maps from `\begin{exampleblock}`.
- **`callout-danger`**: Security warnings, destructive operations, critical pitfalls.
- **`case-study`**: Scenario-based problems — maps from `\begin{casestudy}`.
- **`case-solution`**: Answers to case studies — maps from `\begin{casesolution}`.

---

## 10. Learning Outcomes & Review Sections

### Learning Outcomes

Every chapter begins (after the header) with a learning outcomes block:

```html
<div class="learning-outcomes">
    <h3>Learning Outcomes</h3>
    <p>After completing this module, you will be able to:</p>
    <ul>
        <li>Define fundamental <strong class="key-term">networking concepts</strong> and terminology.</li>
        <li>Identify different <strong class="key-term">network types</strong> including LAN, WAN, PAN, MAN, and CAN.</li>
        <!-- ... -->
    </ul>
</div>
```

Source: The `\begin{frame}{Learning Outcomes}` frame in each module.

### Review from Previous Module

If the module has a `\section*{Review from Module N}` section, render it as:

```html
<div class="review-section">
    <h3>Review from Module N</h3>
    <p>In the previous module, we learned about...</p>
    <!-- Summarize the review frames as prose -->
</div>
```

### Module Summary

If the module ends with a summary section, use:

```html
<div class="module-summary">
    <h2>Module Summary</h2>
    <p>In this module, we covered...</p>
    <ul>
        <li>...</li>
    </ul>
</div>
```

---

## 11. Images

If the LaTeX source references non-TikZ images (e.g., `\includegraphics{images/...}`),
include them with:

```html
<figure>
    <img src="../../images/path/to/image.png" alt="Descriptive alt text">
    <figcaption>Figure N: Description of the image.</figcaption>
</figure>
```

Most diagrams should be **Mermaid**, not images. Only use `<img>` for photos, screenshots,
or externally sourced figures.

---

## 12. Navigation & Sidebar

### Sidebar Table of Contents

The sidebar should list all `<h2>` and `<h3>` elements from the chapter:

- `<h2>` entries get class `toc-h2`
- `<h3>` entries get class `toc-h3` (indented via CSS)

### Chapter Navigation (prev/next)

At the bottom of each chapter, include navigation links:

```html
<nav class="chapter-nav">
    <a href="../network_01_basics/index.html">&larr; Previous: Networking Basics</a>
    <a href="../network_03_switches_interfaces/index.html">Next: Switches &amp; Interfaces &rarr;</a>
</nav>
```

- Module 01 has no "Previous" link.
- Module 11 has no "Next" link.

---

## 13. Accessibility

- Every `<img>` must have a meaningful `alt` attribute.
- Every Mermaid diagram must have an adjacent `<p class="diagram-caption">` describing
  what it shows (this also serves as alt text since Mermaid renders to SVG).
- Use semantic HTML: `<nav>`, `<main>`, `<aside>`, `<header>`, `<footer>`, `<figure>`,
  `<figcaption>`, `<table>`, `<thead>`, `<tbody>`.
- Heading hierarchy must not skip levels (no `<h2>` then `<h4>`).
- Tables should use `<th>` elements with `scope="col"` or `scope="row"` where appropriate.

---

## 14. Quality Checklist

Before finalizing each chapter, verify:

- [ ] **Valid HTML5** — proper `<!DOCTYPE html>`, `<html lang="en">`, `<meta charset="utf-8">`
- [ ] **CSS linked** — `<link rel="stylesheet" href="../css/lectures.css">`
- [ ] **Mermaid loaded** — `<script type="module">` with CDN import
- [ ] **All TikZ diagrams** converted to Mermaid or omitted if purely decorative
- [ ] **No `\presentationonly` content** in the output
- [ ] **All `\articleonly` content** is included
- [ ] **Key terms** use `<strong class="key-term">`
- [ ] **Bullet points expanded** into prose paragraphs (not raw slide bullets)
- [ ] **Callout boxes** used for blocks, alertblocks, case studies
- [ ] **Learning outcomes** present at top of chapter
- [ ] **Sidebar TOC** matches actual headings in the document
- [ ] **Prev/Next navigation** links correct
- [ ] **No broken links** or placeholder text
- [ ] **Alt text** on all images and captions on all diagrams
- [ ] **Heading IDs** present and match sidebar links
- [ ] **No LaTeX artifacts** (`\\`, `\textbf`, `$...$`, `\begin{...}`) in output

---

## 15. Module Registry

| Module | TeX Source File | HTML Directory | Title |
|--------|----------------|----------------|-------|
| 01 | `network_01_basics.tex` | `HTML/network_01_basics/` | Introduction to Networking Fundamentals |
| 02 | `network_02_phys_inf.tex` | `HTML/network_02_phys_inf/` | Supporting Cabling and Physical Installations |
| 03 | `network_03_switches_interfaces.tex` | `HTML/network_03_switches_interfaces/` | Switches & Interfaces |
| 04 | `network_04_IP.tex` | `HTML/network_04_IP/` | IP Addressing & Subnetting |
| 05 | `network_05_routing.tex` | `HTML/network_05_routing/` | Routing, Switching, and Network Infrastructure |
| 06 | `network_06_nw_services.tex` | `HTML/network_06_nw_services/` | Network Services |
| 07 | `network_07_nw_app.tex` | `HTML/network_07_nw_app/` | Applications & Services |
| 08 | `network_08_operations_monitor.tex` | `HTML/network_08_operations_monitor/` | Operations & Monitoring |
| 09 | `network_09_security_concepts.tex` | `HTML/network_09_security_concepts/` | Security Concepts |
| 10 | `network_10_auth_access_hardening.tex` | `HTML/network_10_auth_access_hardening/` | Identity, Access, and Network Hardening |
| 11 | `network_11_zones_iot_physical.tex` | `HTML/network_11_zones_iot_physical/` | Zone-Based Security, IoT, and Physical Security |
