"""
Summary statistics utilities for version fetchers.

Provides consistent summary output across all fetchers for monitoring
and data quality analysis.
"""

import time
from typing import Dict, Any, List, Optional
from datetime import datetime


class FetcherStats:
    """
    Track and display fetcher statistics.
    
    Provides consistent summary format across all fetchers.
    """
    
    def __init__(self, ecosystem: str):
        """
        Initialize statistics tracker.
        
        Args:
            ecosystem: Name of the ecosystem (npm, pypi, etc.)
        """
        self.ecosystem = ecosystem
        self.start_time = time.time()
        self.stats = {
            'total_packages': 0,
            'successful': 0,
            'failed': 0,
            'skipped_cached': 0,
            'with_versions': 0,
            'no_versions': 0,
            'api_calls': 0,
            'total_versions_fetched': 0
        }
    
    def increment(self, key: str, amount: int = 1):
        """
        Increment a statistic.
        
        Args:
            key: Statistic key
            amount: Amount to increment by
        """
        if key in self.stats:
            self.stats[key] += amount
        else:
            self.stats[key] = amount
    
    def set(self, key: str, value: Any):
        """
        Set a statistic value.
        
        Args:
            key: Statistic key
            value: Value to set
        """
        self.stats[key] = value
    
    def get(self, key: str, default: Any = 0) -> Any:
        """
        Get a statistic value.
        
        Args:
            key: Statistic key
            default: Default value if key doesn't exist
        
        Returns:
            Statistic value
        """
        return self.stats.get(key, default)
    
    def elapsed_time(self) -> float:
        """
        Get elapsed time since initialization.
        
        Returns:
            Elapsed time in seconds
        """
        return time.time() - self.start_time
    
    def print_summary(self, title: Optional[str] = None):
        """
        Print formatted summary statistics.
        
        Args:
            title: Optional custom title
        """
        if title is None:
            title = f"{self.ecosystem.upper()} FETCHER SUMMARY"
        
        elapsed = self.elapsed_time()
        
        print()
        print("=" * 70)
        print(title)
        print("=" * 70)
        
        # Basic counts
        print()
        print("Package Counts:")
        print(f"  Total packages:      {self.stats['total_packages']:,}")
        print(f"  ✓ Successful:        {self.stats['successful']:,}")
        print(f"  ✗ Failed:            {self.stats['failed']:,}")
        print(f"  ⊙ Skipped (cached):  {self.stats['skipped_cached']:,}")
        
        # Version counts
        if self.stats['successful'] > 0:
            print()
            print("Version Counts:")
            print(f"  ✓ With versions:     {self.stats['with_versions']:,}")
            print(f"  ⚠  No versions:      {self.stats['no_versions']:,}")
            print(f"  Total versions:      {self.stats['total_versions_fetched']:,}")
            
            if self.stats['with_versions'] > 0:
                avg_versions = self.stats['total_versions_fetched'] / self.stats['with_versions']
                print(f"  Avg per package:     {avg_versions:.1f}")
        
        # Performance
        print()
        print("Performance:")
        print(f"  API calls made:      {self.stats['api_calls']:,}")
        print(f"  Execution time:      {elapsed:.1f}s")
        
        if self.stats['successful'] > 0:
            rate = self.stats['successful'] / elapsed
            print(f"  Fetch rate:          {rate:.1f} packages/sec")
        
        # Success rate
        if self.stats['total_packages'] > 0:
            success_rate = (self.stats['successful'] / self.stats['total_packages']) * 100
            print()
            print(f"Success Rate: {success_rate:.1f}%")
        
        print("=" * 70)
    
    def to_dict(self) -> Dict[str, Any]:
        """
        Export statistics as dictionary.
        
        Returns:
            Dictionary with all statistics
        """
        return {
            'ecosystem': self.ecosystem,
            'timestamp': datetime.utcnow().isoformat() + 'Z',
            'elapsed_time_seconds': self.elapsed_time(),
            'stats': self.stats.copy()
        }
    
    def print_progress(self, current: int, total: int, package_name: str):
        """
        Print progress indicator.
        
        Args:
            current: Current package number
            total: Total packages
            package_name: Name of current package
        """
        percentage = (current / total) * 100 if total > 0 else 0
        print(f"[{current}/{total}] ({percentage:.1f}%) {package_name}")


class MultiEcosystemStats:
    """
    Track statistics across multiple ecosystems.
    
    Useful for batch processing or comparison.
    """
    
    def __init__(self):
        """Initialize multi-ecosystem statistics tracker."""
        self.ecosystem_stats: Dict[str, FetcherStats] = {}
        self.start_time = time.time()
    
    def add_ecosystem(self, ecosystem: str) -> FetcherStats:
        """
        Add an ecosystem to track.
        
        Args:
            ecosystem: Ecosystem name
        
        Returns:
            FetcherStats instance for the ecosystem
        """
        if ecosystem not in self.ecosystem_stats:
            self.ecosystem_stats[ecosystem] = FetcherStats(ecosystem)
        return self.ecosystem_stats[ecosystem]
    
    def get_ecosystem(self, ecosystem: str) -> Optional[FetcherStats]:
        """
        Get statistics for an ecosystem.
        
        Args:
            ecosystem: Ecosystem name
        
        Returns:
            FetcherStats instance or None
        """
        return self.ecosystem_stats.get(ecosystem)
    
    def print_combined_summary(self):
        """Print combined summary for all ecosystems."""
        elapsed = time.time() - self.start_time
        
        print()
        print("=" * 70)
        print("COMBINED MULTI-ECOSYSTEM SUMMARY")
        print("=" * 70)
        
        total_packages = sum(s.stats['total_packages'] for s in self.ecosystem_stats.values())
        total_successful = sum(s.stats['successful'] for s in self.ecosystem_stats.values())
        total_failed = sum(s.stats['failed'] for s in self.ecosystem_stats.values())
        total_versions = sum(s.stats['total_versions_fetched'] for s in self.ecosystem_stats.values())
        
        print()
        print(f"Ecosystems processed: {len(self.ecosystem_stats)}")
        print(f"Total packages:       {total_packages:,}")
        print(f"✓ Successful:         {total_successful:,}")
        print(f"✗ Failed:             {total_failed:,}")
        print(f"Total versions:       {total_versions:,}")
        print(f"Execution time:       {elapsed:.1f}s")
        
        if total_packages > 0:
            success_rate = (total_successful / total_packages) * 100
            print(f"Overall success rate: {success_rate:.1f}%")
        
        print()
        print("By Ecosystem:")
        for ecosystem, stats in sorted(self.ecosystem_stats.items()):
            success_rate = 0
            if stats.stats['total_packages'] > 0:
                success_rate = (stats.stats['successful'] / stats.stats['total_packages']) * 100
            print(f"  {ecosystem:15s}: {stats.stats['successful']:4d}/{stats.stats['total_packages']:4d} ({success_rate:5.1f}%)")
        
        print("=" * 70)


def format_duration(seconds: float) -> str:
    """
    Format duration in human-readable format.
    
    Args:
        seconds: Duration in seconds
    
    Returns:
        Formatted string (e.g., "1h 23m 45s")
    """
    if seconds < 60:
        return f"{seconds:.1f}s"
    elif seconds < 3600:
        minutes = int(seconds / 60)
        secs = seconds % 60
        return f"{minutes}m {secs:.0f}s"
    else:
        hours = int(seconds / 3600)
        minutes = int((seconds % 3600) / 60)
        secs = seconds % 60
        return f"{hours}h {minutes}m {secs:.0f}s"


def format_number(num: int) -> str:
    """
    Format number with thousands separators.
    
    Args:
        num: Number to format
    
    Returns:
        Formatted string (e.g., "1,234,567")
    """
    return f"{num:,}"