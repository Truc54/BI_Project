import os
from pathlib import Path
import shutil
import subprocess
import sys
try:
    from mage_ai.settings.repo import get_repo_path
except ImportError:
    def get_repo_path():
        return os.getcwd()

if 'custom' not in globals():
    try:
        from mage_ai.data_preparation.decorators import custom
    except ImportError:
        def custom(f):
            return f

if 'test' not in globals():
    try:
        from mage_ai.data_preparation.decorators import test
    except ImportError:
        def test(f):
            return f


def find_dbt_project_dir() -> Path:
    """
    Xác định đường dẫn thư mục dbt project:
    - Trong Mage Docker container: /home/src/dbt
    - Khi chạy trên host hoặc repo path: ../dbt
    """
    candidates = [
        Path('/home/src/dbt'),
        Path(__file__).resolve().parent.parent.parent / 'dbt',
        Path(get_repo_path()).parent / 'dbt',
        Path('dbt'),
    ]
    for p in candidates:
        if p.exists() and (p / 'dbt_project.yml').exists():
            return p.resolve()
    
    raise FileNotFoundError(
        f"Không tìm thấy dbt_project.yml trong các thư mục kiểm tra: {[str(c) for c in candidates]}"
    )


def execute_dbt_command(command: list[str], cwd: Path) -> None:
    """
    Thực thi lệnh dbt với output streaming thời gian thực ra stdout/Mage logger.
    Ném ngoại lệ RuntimeError nếu mã thoát khác 0.
    """
    cmd_str = ' '.join(command)
    print(f"\n==================================================")
    print(f"[dbt] Đang thực thi: {cmd_str}")
    print(f"[dbt] Working Directory: {cwd}")
    print(f"==================================================\n", flush=True)

    env = os.environ.copy()
    # Đảm bảo mã hóa UTF-8 cho dbt
    env['PYTHONIOENCODING'] = 'utf-8'

    process = subprocess.Popen(
        command,
        cwd=str(cwd),
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
        universal_newlines=True,
        env=env,
    )

    output_lines = []
    if process.stdout:
        for line in iter(process.stdout.readline, ''):
            print(line, end='', flush=True)
            output_lines.append(line)
        process.stdout.close()

    exit_code = process.wait()
    if exit_code != 0:
        error_detail = ''.join(output_lines[-20:])  # 20 dòng cuối cùng
        raise RuntimeError(
            f"Lệnh dbt thất bại với exit code {exit_code}!\n"
            f"Chi tiết lỗi gần nhất:\n{error_detail}"
        )


@custom
def run_dbt_transforms(payload, *args, **kwargs):
    """
    Kích hoạt dbt biến đổi dữ liệu sau khi commit watermark thành công:
    1. Chạy dbt run: biên dịch và thực thi Staging (clean_view) và Marts (dds).
    2. Chạy dbt test: kiểm thử toàn bộ ràng buộc schema và business logic.
    """
    print(f"[✓] Nhận tín hiệu từ commit_watermark: {payload}")

    dbt_dir = find_dbt_project_dir()
    dbt_bin = shutil.which('dbt') or 'dbt'

    # Cho phép tùy biến qua runtime variables (ví dụ: kwargs.get('run_tests', True))
    run_tests = kwargs.get('dbt_run_tests', True)
    dbt_select = kwargs.get('dbt_select', None)

    # 1. dbt run
    run_cmd = [
        dbt_bin, 'run',
        '--project-dir', str(dbt_dir),
        '--profiles-dir', str(dbt_dir),
    ]
    if dbt_select:
        run_cmd.extend(['--select', str(dbt_select)])

    execute_dbt_command(run_cmd, dbt_dir)

    # 2. dbt test (nếu được kích hoạt)
    if run_tests:
        test_cmd = [
            dbt_bin, 'test',
            '--project-dir', str(dbt_dir),
            '--profiles-dir', str(dbt_dir),
        ]
        if dbt_select:
            test_cmd.extend(['--select', str(dbt_select)])
        execute_dbt_command(test_cmd, dbt_dir)

    print("\n[✓] Toàn bộ quá trình dbt transform & test đã hoàn thành thành công!")

    return {
        'status': 'SUCCESS',
        'dbt_project': str(dbt_dir),
        'watermark_payload': payload,
    }


@test
def test_output(output, *args) -> None:
    """
    Kiểm thử đầu ra của block run_dbt_transforms
    """
    assert output is not None, 'Kết quả đầu ra của block dbt không được để trống'
    assert output.get('status') == 'SUCCESS', 'Tiến trình dbt không trả về trạng thái SUCCESS'
