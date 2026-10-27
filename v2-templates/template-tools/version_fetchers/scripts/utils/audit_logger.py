"""
Audit logging utilities for tracking packages with no versions found.

Provides centralized logging to CSV and JSON formats for security audits
and data quality monitoring.
"""

import csv
import json
import threading
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Any


class AuditLogger:
    """
    Thread-safe audit logger for tracking packages with no versions.
    
    Logs to both CSV (human-readable) and JSON (machine-readable) formats.
    Each ecosystem gets separate log files.
    
    Example:
        >>> logger = AuditLogger(output_dir=Path("../version_data"))
        >>> logger.log_no_versions(
        ...     package_name="express",
        ...     ecosystem="npm",
        ...     attempted_sources=["npm_registry"],
        ...     package_url="https://github.com/expressjs/express"
        ... )
    """
    
    def __init__(self, output_dir: Path):
        """
        Initialize audit logger.
        
        Args:
            output_dir: Directory where audit logs will be written
        """
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self._lock = threading.Lock()
        self._csv_files = {}
        self._csv_writers = {}
        self._json_data = {}
    
    def log_no_versions(
        self,
        package_name: str,
        ecosystem: str,
        attempted_sources: List[str],
        package_url: Optional[str] = None,
        script_path: Optional[str] = None,
        **metadata
    ):
        """
        Log a package that had no versions found.
        
        Args:
            package_name: Name of the package
            ecosystem: Ecosystem (npm, pypi, maven, packagist, go, rubygems)
            attempted_sources: List of sources attempted (e.g., ['npm_registry', 'github'])
            package_url: Optional URL to package repository
            script_path: Optional path to build script
            **metadata: Additional metadata to include
        """
        with self._lock:
            timestamp = datetime.utcnow().isoformat() + 'Z'
            
            # Prepare log entry
            entry = {
                'timestamp': timestamp,
                'package_name': package_name,
                'ecosystem': ecosystem.lower(),
                'attempted_sources': attempted_sources,
                'package_url': package_url or '',
                'script_path': script_path or '',
                **metadata
            }
            
            # Write to CSV
            self._write_csv(ecosystem, entry)
            
            # Write to JSON
            self._write_json(ecosystem, entry)
    
    def _write_csv(self, ecosystem: str, entry: Dict[str, Any]):
        """Write entry to CSV file."""
        ecosystem = ecosystem.lower()
        csv_path = self.output_dir / f"{ecosystem}_no_versions.csv"
        
        # Open file if not already open
        if ecosystem not in self._csv_files:
            file_exists = csv_path.exists()
            self._csv_files[ecosystem] = open(csv_path, 'a', newline='', encoding='utf-8')
            self._csv_writers[ecosystem] = csv.DictWriter(
                self._csv_files[ecosystem],
                fieldnames=[
                    'timestamp', 'package_name', 'ecosystem', 'attempted_sources',
                    'package_url', 'script_path', 'notes'
                ],
                extrasaction='ignore'
            )
            
            # Write header if new file
            if not file_exists:
                self._csv_writers[ecosystem].writeheader()
        
        # Convert list to string for CSV
        entry_copy = entry.copy()
        if isinstance(entry_copy.get('attempted_sources'), list):
            entry_copy['attempted_sources'] = ','.join(entry_copy['attempted_sources'])
        
        # Write row
        self._csv_writers[ecosystem].writerow(entry_copy)
        self._csv_files[ecosystem].flush()
    
    def _write_json(self, ecosystem: str, entry: Dict[str, Any]):
        """Write entry to JSON file."""
        ecosystem = ecosystem.lower()
        json_path = self.output_dir / f"{ecosystem}_no_versions.json"
        
        # Load existing data if not in memory
        if ecosystem not in self._json_data:
            if json_path.exists():
                with open(json_path, 'r', encoding='utf-8') as f:
                    self._json_data[ecosystem] = json.load(f)
            else:
                self._json_data[ecosystem] = []
        
        # Append entry
        self._json_data[ecosystem].append(entry)
        
        # Write back to file
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(self._json_data[ecosystem], f, indent=2, ensure_ascii=False)
    
    def get_stats(self, ecosystem: Optional[str] = None) -> Dict[str, int]:
        """
        Get statistics about logged packages.
        
        Args:
            ecosystem: Optional ecosystem to filter by
        
        Returns:
            Dictionary with counts per ecosystem
        """
        with self._lock:
            if ecosystem:
                ecosystem = ecosystem.lower()
                return {ecosystem: len(self._json_data.get(ecosystem, []))}
            else:
                return {
                    eco: len(data)
                    for eco, data in self._json_data.items()
                }
    
    def close(self):
        """Close all open file handles."""
        with self._lock:
            for f in self._csv_files.values():
                f.close()
            self._csv_files.clear()
            self._csv_writers.clear()
    
    def __enter__(self):
        """Context manager entry."""
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit."""
        self.close()
        return False


def create_audit_summary(output_dir: Path) -> Dict[str, Any]:
    """
    Create a summary report of all audit logs.
    
    Args:
        output_dir: Directory containing audit logs
    
    Returns:
        Dictionary with summary statistics
    """
    output_dir = Path(output_dir)
    summary = {
        'generated_at': datetime.utcnow().isoformat() + 'Z',
        'ecosystems': {}
    }
    
    # Scan for JSON audit files
    for json_file in output_dir.glob('*_no_versions.json'):
        ecosystem = json_file.stem.replace('_no_versions', '')
        
        try:
            with open(json_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            summary['ecosystems'][ecosystem] = {
                'total_packages': len(data),
                'log_file': str(json_file.name),
                'csv_file': f"{ecosystem}_no_versions.csv"
            }
        except Exception as e:
            summary['ecosystems'][ecosystem] = {
                'error': str(e)
            }
    
    return summary