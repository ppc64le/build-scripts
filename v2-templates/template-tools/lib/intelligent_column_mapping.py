class ColumnMapper:
    """Intelligent column mapping"""
    
    # Known column name variations
    COLUMN_MAPPINGS = {
        'name': ['name', 'package name', 'package_name', 'pkg', 'package', 'component'],
        'version': ['version', 'package version', 'package_version', 'ver', 'release'],
        'language': ['language', 'technology', 'tech', 'stack', 'platform', 'lang'],
        'language_version': ['language version', 'technology version', 'tech version',
                            'language_version', 'technology_version'],
        'url': ['url', 'github url', 'github_url', 'repo url', 'repository', 'homepage', 'package_url'],
        'download_url': ['download url', 'download_url', 'source url', 'source_url'],
        'purl': ['purl'],  # SBOM format - only exact 'purl' to avoid ambiguity with package_url
        'license': ['licenseexpressions', 'license expressions', 'license', 'licenses'],  # SBOM format
        'type': ['type', 'component type', 'component_type'],  # SBOM format
    }
    
    def _inspect_column_content(self, df: pd.DataFrame, col_name: str,
                               suspected_type: str) -> str:
        """
        Inspect actual column data to determine true type
        
        This provides content-based disambiguation for ambiguous column names.
        For example, 'package_url' could contain either GitHub URLs or PURLs.
        
        Args:
            df: DataFrame with the column
            col_name: Column name to inspect
            suspected_type: Type based on column name ('purl' or 'url')
        
        Returns:
            Confirmed type: 'purl', 'url', or 'unknown'
        """
        # Sample first 10 non-null values
        sample_size = min(10, len(df))
        samples = df[col_name].dropna().head(sample_size)
        
        if samples.empty:
            return 'unknown'
        
        # Count format patterns
        purl_count = 0
        url_count = 0
        
        for value in samples:
            value_str = str(value).strip().lower()
            
            # PURL format: pkg:type/name@version
            if value_str.startswith('pkg:'):
                purl_count += 1
            # Regular URL formats
            elif value_str.startswith(('http://', 'https://', 'git://', 'ssh://', 'ftp://')):
                url_count += 1
        
        # Determine type based on majority
        if purl_count > url_count:
            return 'purl'
        elif url_count > purl_count:
            return 'url'
        else:
            return 'unknown'
    
    def map_columns(self, df: pd.DataFrame) -> Tuple[Dict[str, str], Dict[str, str]]:
        """
        Map DataFrame columns to standard schema with content-based disambiguation
        
        Phase 1: Name-based mapping using COLUMN_MAPPINGS
        Phase 2: Content-based disambiguation for ambiguous fields
        
        Returns:
            (forward_map, reverse_map)
            forward_map: {original_col: standard_col}
            reverse_map: {standard_col: original_col}
        """
        forward_map = {}
        reverse_map = {}
        
        # PHASE 1: Name-based mapping
        for col in df.columns:
            col_lower = str(col).lower().strip()
            
            # Try to match to standard columns
            for standard_col, variations in self.COLUMN_MAPPINGS.items():
                if col_lower in variations:
                    forward_map[col] = standard_col
                    reverse_map[standard_col] = col
                    logger.info(f"Mapped '{col}' → '{standard_col}' (name-based)")
                    break
        
        # PHASE 2: Content-based disambiguation for ambiguous columns
        # These fields might be confused based on name alone
        ambiguous_fields = ['purl', 'url']
        
        for field in ambiguous_fields:
            if field in reverse_map:
                original_col = reverse_map[field]
                
                # Inspect actual data to confirm type
                actual_type = self._inspect_column_content(df, original_col, field)
                
                # If mismatch detected, remap
                if actual_type != field and actual_type != 'unknown':
                    logger.warning(f"Column '{original_col}' mapped to '{field}' but contains '{actual_type}' data")
                    logger.info(f"Remapping '{original_col}' from '{field}' to '{actual_type}' (content-based)")
                    
                    # Remove old mapping
                    del reverse_map[field]
                    del forward_map[original_col]
                    
                    # Add new mapping
                    forward_map[original_col] = actual_type
                    reverse_map[actual_type] = original_col
        
        # Check for required columns (can be extracted from PURL if present)
        required = ['name', 'version', 'language']
        missing = [col for col in required if col not in reverse_map]
        
        # If PURL is present, we can extract name/version/language from it
        if missing and 'purl' in reverse_map:
            logger.info(f"Missing {missing} but PURL present - will extract from PURL")
        elif missing:
            logger.error(f"Missing required columns: {missing}")
            logger.error(f"Available columns: {list(df.columns)}")
            raise ValueError(f"Missing required columns: {missing}")
        
        return forward_map, reverse_map

