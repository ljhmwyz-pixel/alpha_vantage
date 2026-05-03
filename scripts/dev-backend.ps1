Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Push-Location "$PSScriptRoot\..\backend"
try {
    if (-not (Test-Path ".venv")) {
        python -m venv .venv
    }

    .\.venv\Scripts\python.exe -m pip install --upgrade pip
    .\.venv\Scripts\python.exe -m pip install -e ".[dev]"

    if (-not (Test-Path ".env")) {
        Copy-Item "..\.env.example" ".env"
    }

    .\.venv\Scripts\alembic.exe upgrade head
    .\.venv\Scripts\uvicorn.exe app.main:app --reload
}
finally {
    Pop-Location
}
