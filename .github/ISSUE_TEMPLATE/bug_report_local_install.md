---
name: Local installation bug report
about: Create a bug report
labels:
- bug
- area/local_installation
---

<!--
Thank you for helping to improve our Terraform module!

Please be sure to search for open issues before raising a new one. We use issues
for bug reports and feature requests. Please note, this template is for bugs
report, not feature requests.
-->

<!-- markdownlint-disable-next-line MD041 -->
### Describe the bug

<!--
Please let us know what behavior you expected and how helmfilelint diverged
from that behavior.
-->

### How can we reproduce it?

<!--
Help us to reproduce your bug as succinctly and precisely as possible. Any and
all steps or script that triggers the issue are highly appreciated!

Do you have long logs to share? Please use collapsible sections, that can be created via:

<details><summary>SECTION_NAME</summary>

```bash
YOUR_LOG_HERE
```

</details>
-->

### Environment information

* OS:
<!-- I.e.:
OS: Windows 10
OS: Win10 with Ubuntu 20.04 on WSL2
OS: MacOS
OS: Ubuntu 20.04
-->

* `uname -a` and/or `systeminfo | Select-String "^OS"` output:

```bash
INSERT_OUTPUT_HERE
```

<!-- I.e.:
```bash
PS C:\Users\user> systeminfo | Select-String "^OS"

OS Name:                   Microsoft Windows 11 Pro
OS Version:                10.0.22621 N/A Build 22621
OS Manufacturer:           Microsoft Corporation
OS Configuration:          Standalone Workstation
OS Build Type:             Multiprocessor Free

$ uname -a
Linux MYPC 5.15.133.1-microsoft-standard-WSL2 #1 SMP Thu Oct 5 21:02:42 UTC 2023 x86_64 x86_64 x86_64 GNU/Linux
```
-->

* Tools availability and versions:

<!--  For check all needed version run next script:

bash << EOF
bash --version | head -n 1                2>/dev/null || echo "bash SKIPPED"
terraform version                         2>/dev/null || echo "terraform SKIPPED"
EOF

-->

```bash
INSERT_TOOLS_VERSIONS_HERE
```

* `.tf` files:

<!-- markdownlint-disable-next-line MD033 -->
<details><summary>file content</summary>

```bash
INSERT_FILE_CONTENT_HERE
```

</details>
