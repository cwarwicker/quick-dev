#!/usr/bin/bash
# Write the internal hostname to hosts file for use in behat testing.
echo "===== Writing internal hostname"
grep -q "127.0.0.1    internal" /etc/hosts || echo "127.0.0.1    internal" | tee -a /etc/hosts