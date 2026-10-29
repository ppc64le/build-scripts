#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : PyAV
# Version       : v13.1.0
# Source repo   : https://github.com/PyAV-Org/PyAV
# Tested on     : UBI:9.6
# Language      : Python (Cython extensions wrapping FFmpeg)
# Script License: Apache License 2.0
# Maintainer    : IBM
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="PyAV"
PACKAGE_VERSION="${1:-v13.1.0}"
PACKAGE_URL="https://github.com/PyAV-Org/PyAV"

# =============================================================================
# Artifact Declaration (Tier 4 - consumer only, depends on ffmpeg)
# Include ffmpeg's transitive deps (libvpx, lame, opus) so auditwheel can find
# all shared libraries when repairing the wheel
# =============================================================================
BUILD_DEPS="ffmpeg libvpx lame opus"

# =============================================================================
# REQUIRED: Dependencies
# Note: We use our built ffmpeg artifact, not system packages
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ make pkg-config python3-devel python3-pip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_clone
# Source ffmpeg and its transitive dependencies to ensure environment is set up
# This ensures auditwheel can find all shared libraries for wheel repair
# =============================================================================
pre_clone() {
    # Source transitive dependencies first (order matters for LD_LIBRARY_PATH)
    # These are ffmpeg's dependencies that pyav indirectly links against
    if ! source_artifact libvpx; then
        log_error "libvpx artifact not found!"
        log_error "Build libvpx first: l/libvpx/libvpx.sh"
        return 1
    fi

    if ! source_artifact lame; then
        log_error "lame artifact not found!"
        log_error "Build lame first: l/lame/lame.sh"
        return 1
    fi

    if ! source_artifact opus; then
        log_error "opus artifact not found!"
        log_error "Build opus first: o/opus/opus.sh"
        return 1
    fi

    # Source ffmpeg artifact to get PKG_CONFIG_PATH and LD_LIBRARY_PATH
    if ! source_artifact ffmpeg; then
        log_error "FFmpeg artifact not found!"
        log_error "Build ffmpeg first: f/ffmpeg/ffmpeg.sh"
        return 1
    fi

    log_info "Using FFmpeg from: ${FFMPEG_PREFIX:-unknown}"
    log_info "PKG_CONFIG_PATH: ${PKG_CONFIG_PATH:-}"
    log_info "LD_LIBRARY_PATH includes lame, opus, libvpx for auditwheel"
}

# =============================================================================
# CALLBACK: post_clone
# Apply patches and read setuptools version from pyproject.toml 
# to set SETUPTOOLS_VERSION
# =============================================================================
post_clone() {

    log_info "Reading setuptools version from pyproject.toml"
    setuptools_req="$(grep -o '"setuptools[^"]*"' pyproject.toml | head -1 | tr -d '"')"
    SETUPTOOLS_VERSION="${setuptools_req#setuptools}"
    SETUPTOOLS_VERSION="${SETUPTOOLS_VERSION//[[:space:]]/}"

    # Patch virtualenv enforcement for versions >= 15.0.0
    VERSION_STR="${PACKAGE_VERSION#v}"
    version_ge() {
        [ "$(printf '%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
    }

    if version_ge "$VERSION_STR" "15.0.0"; then
        if [[ -f "setup.py" ]]; then
            log_info "Patching virtualenv check in setup.py for version $VERSION_STR..."
            sed -i '
                /if not (os.getenv("GITHUB_ACTIONS") == "true" or is_virtualenv()) *:/ {
                    N
                    s/raise ValueError(.*/print("\\033[1;91mWarning!\\033[0m You are not using a virtual environment")/
                }
            ' setup.py
        fi
    fi
}

# =============================================================================
# CALLBACK: pre_build
# Install cython for building Cython extensions and verify FFmpeg
# =============================================================================
pre_build() {
    log_info "Installing cython for extension compilation..."
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install cython numpy

    # Verify FFmpeg is available via pkg-config
    if ! pkg-config --exists libavcodec libavformat; then
        log_error "FFmpeg development libraries not found via pkg-config!"
        log_error "PKG_CONFIG_PATH: ${PKG_CONFIG_PATH:-not set}"
        log_error "FFMPEG_PREFIX: ${FFMPEG_PREFIX:-not set}"
        return 1
    fi

    log_info "FFmpeg version (libavcodec): $(pkg-config --modversion libavcodec 2>/dev/null || echo 'unknown')"
    log_info "FFmpeg libs: $(pkg-config --libs libavcodec 2>/dev/null || echo 'unknown')"
}

# =============================================================================
# CALLBACK: pre_test
# Install test dependencies
# =============================================================================
pre_test() {
    log_info "Running pre-test setup..."
    log_info "Installing test dependencies..."
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install numpy pillow cython
    python -m pip install --upgrade "pytest>=7.0"

    # Remove plugins that crash during entrypoint loading
    python -m pip uninstall -y pytest-cov pytest-xdist pytest-codspeed 2>/dev/null
}

# =============================================================================
# CALLBACK: custom_test_command
# Run tests with known-failing tests deselected
# Many tests fail due to:
#   - Disabled codecs (h264, hevc, aac, mpeg) for licensing
#   - Network-restricted environment (FATE media downloads blocked)
#   - Platform-specific behavior differences
# =============================================================================
custom_test_command() {
    log_info "Running pytest with platform-specific test deselections..."

    # Test deselections explanation:
    # - test_videoframe.py, test_audiofifo.py, etc.: Depend on disabled codecs
    # - test_timeout.py: Network timing tests
    # - test_bitstream.py, test_chapters.py: Codec-specific tests
    # - test_packet.py, test_seek.py: Format-specific tests
    # - test_python_io.py, test_open.py: I/O tests with specific formats
    # - test_streams.py, test_subtitles.py: Stream/format tests
    # - Various individual tests: Require FATE reference media (HTTP 403 in restricted env)

    python -I -m pytest \
        --import-mode=importlib \
        -o "addopts=" \
        --ignore=tests/test_videoframe.py \
        --ignore=tests/test_timeout.py \
        --ignore=tests/test_audiofifo.py \
        --ignore=tests/test_bitstream.py \
        --ignore=tests/test_chapters.py \
        --ignore=tests/test_packet.py \
        --ignore=tests/test_seek.py \
        --ignore=tests/test_python_io.py \
        --ignore=tests/test_open.py \
        --ignore=tests/test_streams.py \
        --ignore=tests/test_subtitles.py \
        -k "not test_decoded_video_enc_params_no_flag and not test_decoded_video_enc_params and not test_subtitle_encode_mp4 and not test_video_remux and not test_attachment_stream and not test_data_types and not test_qmin_qmax and not test_profiles and not test_printing_video_stream and not test_frame_duration_matches_packet and not test_printing_video_stream2 and not test_no_side_data and not test_encoding_dnxhd and not test_encoding_dvvideo and not test_encoding_h264 and not test_encoding_mjpeg and not test_encoding_mpeg1video and not test_encoding_mpeg4 and not test_encoding_png and not test_encoding_tiff and not test_encoding_xvid and not test_mov and not test_decode_video_corrupt and not test_decoded_motion_vectors and not test_decoded_motion_vectors_no_flag and not test_decoded_time_base and not test_decoded_video_frame_count and not test_flush_decoded_video_frame_count and not test_av_stream_Stream and not test_encoding_with_pts and not test_stream_audio_resample and not test_max_b_frames and not test_container_probing and not test_stream_probing and not test_writing_to_custom_io_dash and not test_decode_half and not test_stream_seek and not test_side_data and not test_opaque and not test_reformat_pixel_format_align and not test_filter_output_parameters and not test_codec_mpeg4_decoder and not test_codec_mpeg4_encoder and not test_codec_delay and not test_codec_tag and not test_decoder_extradata and not test_decoder_gop_size and not test_decoder_timebase and not test_encoder_extradata and not test_encoder_pix_fmt and not test_parse and not test_sky_timelapse and not test_av_codec_codec_Codec and not test_av_enum_EnumFlag and not test_av_enum_EnumItem and not test_default_options and not test_encoding and not test_encoding_with_unicode_filename and not test_stream_index and not test_writing_to_buffer and not test_writing_to_buffer_broken and not test_writing_to_buffer_broken_with_close and not test_writing_to_file and not test_writing_to_pipe_writeonly and not test_bits_per_coded_sample and not test_penguin_joke and not test_decode_audio_sample_count and not test_decode_close_then_use and not test_transcode and not test_subtitle_muxing and not test_interpolation" \
        --disable-warnings
}

# =============================================================================
# CALLBACK: pre_wheel
# Re-source artifacts before auditwheel repair to ensure LD_LIBRARY_PATH is set
# auditwheel needs to find all transitive dependencies (libvpx, lame, opus)
# =============================================================================
pre_wheel() {
    log_info "Re-sourcing artifacts for auditwheel repair..."

    # Source all dependencies to ensure LD_LIBRARY_PATH includes their lib dirs
    source_artifact libvpx || log_warn "libvpx artifact not found"
    source_artifact lame || log_warn "lame artifact not found"
    source_artifact opus || log_warn "opus artifact not found"
    source_artifact ffmpeg || log_warn "ffmpeg artifact not found"

    log_info "LD_LIBRARY_PATH for auditwheel: ${LD_LIBRARY_PATH:-not set}"
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"