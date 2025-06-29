#!/usr/bin/env python3
"""
Custom Terraform Security Check Script
This script performs additional security checks on Terraform files
"""

import os
import re
import sys
import json
from pathlib import Path
from typing import List, Dict, Any

class TerraformSecurityChecker:
    def __init__(self):
        self.issues = []
        self.terraform_files = []

    def find_terraform_files(self, directory: str = ".") -> List[str]:
        """Find all Terraform files in the directory"""
        terraform_extensions = ['.tf', '.tfvars', '.tfstate']
        files = []

        for root, dirs, filenames in os.walk(directory):
            # Skip .terraform and .git directories
            dirs[:] = [d for d in dirs if d not in ['.terraform', '.git', 'node_modules']]

            for filename in filenames:
                if any(filename.endswith(ext) for ext in terraform_extensions):
                    files.append(os.path.join(root, filename))

        return files

    def check_hardcoded_secrets(self, file_path: str) -> List[Dict[str, Any]]:
        """Check for hardcoded secrets in Terraform files"""
        issues = []
        secret_patterns = [
            r'password\s*=\s*["\'][^"\']+["\']',
            r'secret\s*=\s*["\'][^"\']+["\']',
            r'token\s*=\s*["\'][^"\']+["\']',
            r'key\s*=\s*["\'][^"\']+["\']',
            r'access_key\s*=\s*["\'][^"\']+["\']',
            r'secret_key\s*=\s*["\'][^"\']+["\']',
            r'private_key\s*=\s*["\'][^"\']+["\']',
        ]

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                lines = content.split('\n')

                for line_num, line in enumerate(lines, 1):
                    for pattern in secret_patterns:
                        if re.search(pattern, line, re.IGNORECASE):
                            issues.append({
                                'file': file_path,
                                'line': line_num,
                                'issue': 'Potential hardcoded secret found',
                                'severity': 'HIGH',
                                'line_content': line.strip()
                            })
        except Exception as e:
            issues.append({
                'file': file_path,
                'line': 0,
                'issue': f'Error reading file: {str(e)}',
                'severity': 'ERROR'
            })

        return issues

    def check_insecure_defaults(self, file_path: str) -> List[Dict[str, Any]]:
        """Check for insecure default configurations"""
        issues = []
        insecure_patterns = [
            (r'cidr_blocks\s*=\s*\[["\']0\.0\.0\.0/0["\']\]', 'Open CIDR block (0.0.0.0/0)'),
            (r'from_port\s*=\s*22', 'SSH port 22 exposed'),
            (r'from_port\s*=\s*3389', 'RDP port 3389 exposed'),
            (r'protocol\s*=\s*["\']-1["\']', 'All protocols (-1) allowed'),
            (r'encryption\s*=\s*false', 'Encryption disabled'),
            (r'force_destroy\s*=\s*true', 'Force destroy enabled'),
            (r'deletion_protection\s*=\s*false', 'Deletion protection disabled'),
        ]

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                lines = content.split('\n')

                for line_num, line in enumerate(lines, 1):
                    for pattern, description in insecure_patterns:
                        if re.search(pattern, line, re.IGNORECASE):
                            issues.append({
                                'file': file_path,
                                'line': line_num,
                                'issue': f'Insecure configuration: {description}',
                                'severity': 'MEDIUM',
                                'line_content': line.strip()
                            })
        except Exception as e:
            issues.append({
                'file': file_path,
                'line': 0,
                'issue': f'Error reading file: {str(e)}',
                'severity': 'ERROR'
            })

        return issues

    def check_missing_tags(self, file_path: str) -> List[Dict[str, Any]]:
        """Check for missing required tags"""
        issues = []
        required_tags = ['Environment', 'Project', 'ManagedBy']

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

                # Find all resource blocks
                resource_blocks = re.finditer(r'resource\s+"([^"]+)"\s+"([^"]+)"\s*{', content)

                for match in resource_blocks:
                    resource_type = match.group(1)
                    resource_name = match.group(2)

                    # Skip certain resource types that don't need tags
                    if resource_type in ['aws_iam_role_policy_attachment', 'aws_iam_role_policy']:
                        continue

                    # Check if tags block exists
                    start_pos = match.end()
                    end_pos = self.find_block_end(content, start_pos)
                    block_content = content[start_pos:end_pos]

                    if 'tags' not in block_content:
                        issues.append({
                            'file': file_path,
                            'line': content[:start_pos].count('\n') + 1,
                            'issue': f'Missing tags for {resource_type}.{resource_name}',
                            'severity': 'LOW',
                            'resource': f'{resource_type}.{resource_name}'
                        })
        except Exception as e:
            issues.append({
                'file': file_path,
                'line': 0,
                'issue': f'Error reading file: {str(e)}',
                'severity': 'ERROR'
            })

        return issues

    def find_block_end(self, content: str, start_pos: int) -> int:
        """Find the end of a Terraform block"""
        brace_count = 0
        in_string = False
        string_char = None

        for i, char in enumerate(content[start_pos:], start_pos):
            if char in ['"', "'"] and (i == 0 or content[i-1] != '\\'):
                if not in_string:
                    in_string = True
                    string_char = char
                elif char == string_char:
                    in_string = False
                    string_char = None

            if not in_string:
                if char == '{':
                    brace_count += 1
                elif char == '}':
                    brace_count -= 1
                    if brace_count == 0:
                        return i

        return len(content)

    def check_eks_specific_security(self, file_path: str) -> List[Dict[str, Any]]:
        """Check EKS-specific security configurations"""
        issues = []

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

                # Skip outputs.tf files for EKS cluster checks since they don't contain resource definitions
                if file_path.endswith('outputs.tf'):
                    return issues

                # Check for EKS cluster security configurations
                if 'aws_eks_cluster' in content:
                    # Check for encryption configuration
                    if 'encryption_config' not in content:
                        issues.append({
                            'file': file_path,
                            'line': 0,
                            'issue': 'EKS cluster missing encryption configuration',
                            'severity': 'HIGH'
                        })

                    # Check for control plane logging
                    if 'enabled_cluster_log_types' not in content:
                        issues.append({
                            'file': file_path,
                            'line': 0,
                            'issue': 'EKS cluster missing control plane logging',
                            'severity': 'MEDIUM'
                        })

                    # Check for private endpoint access
                    if 'endpoint_private_access' not in content:
                        issues.append({
                            'file': file_path,
                            'line': 0,
                            'issue': 'EKS cluster should have private endpoint access enabled',
                            'severity': 'MEDIUM'
                        })

                # Check for node group security
                if 'aws_eks_node_group' in content:
                    # Check for launch template usage
                    if 'launch_template' not in content:
                        issues.append({
                            'file': file_path,
                            'line': 0,
                            'issue': 'EKS node group should use launch templates for security',
                            'severity': 'MEDIUM'
                        })

                # Check for security groups
                if 'aws_security_group' in content:
                    # Check for security group descriptions
                    if 'description' not in content:
                        issues.append({
                            'file': file_path,
                            'line': 0,
                            'issue': 'Security groups should have descriptions',
                            'severity': 'LOW'
                        })

        except Exception as e:
            issues.append({
                'file': file_path,
                'line': 0,
                'issue': f'Error reading file: {str(e)}',
                'severity': 'ERROR'
            })

        return issues

    def run_checks(self, directory: str = ".") -> Dict[str, Any]:
        """Run all security checks"""
        print("🔍 Running Terraform security checks...")

        # Find Terraform files
        self.terraform_files = self.find_terraform_files(directory)
        print(f"📁 Found {len(self.terraform_files)} Terraform files")

        # Run checks
        for file_path in self.terraform_files:
            print(f"🔍 Checking {file_path}...")

            # Check for hardcoded secrets
            self.issues.extend(self.check_hardcoded_secrets(file_path))

            # Check for insecure defaults
            self.issues.extend(self.check_insecure_defaults(file_path))

            # Check for missing tags
            self.issues.extend(self.check_missing_tags(file_path))

            # Check EKS-specific security
            self.issues.extend(self.check_eks_specific_security(file_path))

        # Generate report
        report = {
            'summary': {
                'total_files': len(self.terraform_files),
                'total_issues': len(self.issues),
                'high_severity': len([i for i in self.issues if i['severity'] == 'HIGH']),
                'medium_severity': len([i for i in self.issues if i['severity'] == 'MEDIUM']),
                'low_severity': len([i for i in self.issues if i['severity'] == 'LOW']),
                'errors': len([i for i in self.issues if i['severity'] == 'ERROR'])
            },
            'issues': self.issues
        }

        return report

    def print_report(self, report: Dict[str, Any]):
        """Print the security check report"""
        summary = report['summary']

        print("\n" + "="*60)
        print("🔒 TERRAFORM SECURITY CHECK REPORT")
        print("="*60)
        print(f"📁 Files scanned: {summary['total_files']}")
        print(f"🚨 Total issues: {summary['total_issues']}")
        print(f"🔴 High severity: {summary['high_severity']}")
        print(f"🟡 Medium severity: {summary['medium_severity']}")
        print(f"🟢 Low severity: {summary['low_severity']}")
        print(f"❌ Errors: {summary['errors']}")
        print("="*60)

        if report['issues']:
            print("\n📋 DETAILED ISSUES:")
            print("-"*60)

            for issue in report['issues']:
                severity_icon = {
                    'HIGH': '🔴',
                    'MEDIUM': '🟡',
                    'LOW': '🟢',
                    'ERROR': '❌'
                }.get(issue['severity'], '⚪')

                print(f"{severity_icon} {issue['severity']}: {issue['issue']}")
                print(f"   📄 File: {issue['file']}")
                if issue.get('line', 0) > 0:
                    print(f"   📍 Line: {issue['line']}")
                if issue.get('line_content'):
                    print(f"   📝 Content: {issue['line_content']}")
                print()
        else:
            print("\n✅ No security issues found!")

        # Save report to file
        with open('security-check-report.json', 'w') as f:
            json.dump(report, f, indent=2)

        print(f"📄 Detailed report saved to: security-check-report.json")

        # Exit with appropriate code
        if summary['high_severity'] > 0:
            print("❌ High severity issues found. Please fix before proceeding.")
            sys.exit(1)
        elif summary['total_issues'] > 0:
            print("⚠️  Issues found. Please review and fix as needed.")
            sys.exit(0)
        else:
            print("✅ All security checks passed!")
            sys.exit(0)

def main():
    """Main function"""
    checker = TerraformSecurityChecker()
    report = checker.run_checks()
    checker.print_report(report)

if __name__ == "__main__":
    main()
