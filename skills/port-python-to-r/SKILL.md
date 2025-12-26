---
name: port-python-to-r
description: Guide for porting Python packages to R using uv and reticulate. This skill should be used when creating R packages that wrap Python functionality, setting up Python-R interoperability, or migrating Python libraries to R environments. Covers environment management, function wrapping strategies, and best practices for maintaining Python dependencies in R packages.
---

# Port Python to R

## Overview

Port Python packages to R by creating wrapper functions that bridge Python functionality through reticulate. This approach allows R users to access Python libraries without rewriting algorithms, maintaining full feature parity while providing an R-native interface.

## Core Architecture

### Three-Layer System

1. **Environment Isolation Layer**: Manage Python virtual environments using `uv` or `reticulate`
2. **Object Proxy Layer**: Use `reticulate` to create R references to Python objects
3. **Data Conversion Layer**: Automatic type conversion between R and Python (handled by `reticulate`)

### Key Principle

**"Don't rewrite, bridge"** - Let R directly control Python objects rather than reimplementing Python functionality in R.

## When to Use This Approach

Use this porting strategy when:

- The Python package has complex algorithms that would be difficult to rewrite in R
- The Python package is actively maintained and frequently updated
- Full feature parity with the Python version is required
- Performance-critical operations should remain in Python's compiled backend
- The R package should automatically benefit from Python package updates

Avoid this approach when:

- The Python package is simple enough to rewrite natively in R
- Python dependencies create deployment complexity that outweighs benefits
- The target audience cannot install Python
- Native R performance is critical (avoid Python bridge overhead)

## Environment Management Strategies

### Strategy 1: User-Managed Environments (Recommended for Flexibility)

Allow users to create and manage their own Python environments.

**Setup instructions for users:**

```bash
# Using uv (modern, fast)
uv venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
uv pip install python-package-name

# Using standard venv
python3 -m venv venv
source venv/bin/activate
pip install python-package-name
```

**R package implementation:**

```r
# R/package-setup.R
get_python_module <- function(venv_path = "./venv") {
  reticulate::use_virtualenv(venv_path, required = TRUE)
  reticulate::import("python_package_name", delay_load = TRUE)
}

# Use memoise for caching
get_python_module <- memoise::memoise(get_python_module)
```

**Advantages:**
- Users have full control over Python environment
- No automatic downloads during package installation
- Easy to use project-specific environments
- Clear separation of R and Python dependencies

**Disadvantages:**
- Requires manual setup steps
- Users must understand Python virtual environments
- More potential for user error

### Strategy 2: Automatic Environment Creation (Recommended for Ease of Use)

Automatically create and manage Python environment when R package loads.

**R package implementation:**

```r
# R/zzz.R
.onLoad <- function(libname, pkgname) {
  # Define persistent environment location
  venv_path <- file.path(Sys.getenv("HOME"), ".package-name", "python_env")
  
  # Create directory if needed
  if (!dir.exists(dirname(venv_path))) {
    dir.create(dirname(venv_path), recursive = TRUE, showWarnings = FALSE)
  }
  
  # Create virtual environment if it doesn't exist
  if (!dir.exists(venv_path)) {
    message("Creating Python virtual environment...")
    tryCatch({
      reticulate::virtualenv_create(venv_path, python = "python3")
      
      # Install required Python packages
      reticulate::virtualenv_install(
        venv_path,
        packages = c("python-package-name", "numpy", "pandas"),
        pip_options = "--upgrade --no-cache-dir"
      )
    }, error = function(e) {
      stop("Failed to create Python environment: ", e$message)
    })
  }
  
  # Use the environment
  reticulate::use_virtualenv(venv_path, required = TRUE)
  
  # Import Python modules
  py_module <<- reticulate::import("python_package_name", delay_load = TRUE)
}
```

**Advantages:**
- Zero-configuration for users
- Consistent environment across installations
- Works out of the box

**Disadvantages:**
- First load is slow (5-10 minutes for large packages like scikit-learn)
- Uses significant disk space (~500MB-1GB)
- Users lose control over Python environment
- May conflict with user's existing Python setup

### Strategy 3: Hybrid Approach (Recommended for Production)

Provide automatic setup with option for user override.

```r
# R/zzz.R
.onLoad <- function(libname, pkgname) {
  # Check for user-specified environment
  user_venv <- Sys.getenv("PACKAGE_VENV", "")
  
  if (user_venv != "" && dir.exists(user_venv)) {
    # Use user-specified environment
    message("Using Python environment: ", user_venv)
    reticulate::use_virtualenv(user_venv, required = TRUE)
  } else {
    # Fall back to automatic creation
    # (implementation from Strategy 2)
  }
  
  py_module <<- reticulate::import("python_package_name", delay_load = TRUE)
}
```

Users can override by setting environment variable:

```r
Sys.setenv(PACKAGE_VENV = "/path/to/custom/venv")
library(your_package)
```

## Function Wrapping Strategies

### Strategy 1: Complete Manual Wrapping (1-20 functions)

Write explicit wrapper functions for each Python class/function.

**When to use:** Small to medium packages (1-20 functions), when full control is needed.

**Template:**

```r
# R/wrappers.R
PythonClassName <- function(
  param1 = default1,
  param2 = default2,
  param3 = default3,
  # ... all Python parameters
  venv_path = "./venv",
  ...) {
  
  # Get Python module
  py_module <- get_python_module(venv_path)
  
  # Call Python class/function
  py_module$PythonClassName(
    param1 = param1,
    param2 = param2,
    param3 = param3,
    # ... pass all parameters
    ...
  )
}
```

**Advantages:**
- Full control over each function
- Excellent IDE autocomplete and documentation
- Can add R-specific parameter validation
- Easy to understand and debug

**Disadvantages:**
- High initial development time (~30 min per function)
- High maintenance cost when Python package updates
- Repetitive code
- Easy to make mistakes (typos, missing parameters)

**Estimated effort:**
- Initial: 30 minutes × number of functions
- Maintenance: 2-4 hours per Python package update

### Strategy 2: Minimal Wrapping with `...` (Quick prototyping)

Use `...` to pass all parameters through to Python.

**When to use:** Rapid prototyping, internal tools, temporary solutions.

**Template:**

```r
PythonClassName <- function(venv_path = "./venv", ...) {
  py_module <- get_python_module(venv_path)
  py_module$PythonClassName(...)
}
```

**Advantages:**
- Extremely fast to implement (3 lines per function)
- Automatically supports all Python parameters
- No maintenance when Python package updates

**Disadvantages:**
- No parameter hints in IDE
- No parameter validation
- Poor user experience
- No documentation for parameters

**Estimated effort:**
- Initial: 5 minutes × number of functions
- Maintenance: Nearly zero

### Strategy 3: Hybrid Wrapping (5-15 functions)

Explicitly declare commonly-used parameters, use `...` for others.

**When to use:** Medium-sized packages where some parameters are used frequently.

**Template:**

```r
PythonClassName <- function(
  # Most commonly used parameters (explicit)
  param1 = default1,
  param2 = default2,
  param3 = default3,
  venv_path = "./venv",
  ...) {  # Less common parameters
  
  py_module <- get_python_module(venv_path)
  py_module$PythonClassName(
    param1 = param1,
    param2 = param2,
    param3 = param3,
    ...
  )
}
```

**Advantages:**
- Good balance of usability and maintainability
- IDE hints for common parameters
- Flexible for advanced users

**Disadvantages:**
- Requires judgment about which parameters to expose
- Partial documentation

**Estimated effort:**
- Initial: 15 minutes × number of functions
- Maintenance: 1-2 hours per Python package update

### Strategy 4: Metaprogramming (20+ functions)

Generate wrapper functions programmatically.

**When to use:** Large packages (20+ functions), frequently updated Python packages.

**Template:**

```r
# R/generate-wrappers.R

# Define wrapper specifications
wrapper_specs <- list(
  PythonClass1 = list(
    params = c("param1", "param2", "param3"),
    defaults = list(param1 = 1L, param2 = 0.5, param3 = "default")
  ),
  PythonClass2 = list(
    params = c("param1", "param4"),
    defaults = list(param1 = 5L, param4 = TRUE)
  )
)

# Generate wrapper function
create_wrapper <- function(class_name, spec, module_getter) {
  force(class_name)
  force(spec)
  force(module_getter)
  
  function(...) {
    args <- list(...)
    py_module <- module_getter(args$venv_path %||% "./venv")
    
    # Remove venv_path from args before passing to Python
    args$venv_path <- NULL
    
    do.call(py_module[[class_name]], args)
  }
}

# Generate all wrappers
for (name in names(wrapper_specs)) {
  assign(name, create_wrapper(name, wrapper_specs[[name]], get_python_module),
         envir = parent.env(environment()))
}
```

**Advantages:**
- Minimal code duplication
- Easy to update when Python package changes
- Consistent behavior across all wrappers

**Disadvantages:**
- More complex to understand
- Harder to debug
- Still requires maintaining parameter lists
- May need custom handling for special cases

**Estimated effort:**
- Initial: 8-12 hours (build generator + specifications)
- Maintenance: 1 hour per Python package update

## Critical Limitations

### Single Python Environment Per R Session

**Key constraint:** Once Python initializes in an R session, the environment cannot be changed without restarting R.

**Implication:**

```r
# First call - initializes Python with venv1
obj1 <- PythonClass(venv_path = "./venv1")  # ✓ Uses venv1

# Second call - tries to use venv2
obj2 <- PythonClass(venv_path = "./venv2")  # ✗ Still uses venv1!
```

**The `venv_path` parameter is effectively ignored after first use.**

**Solutions:**

1. **Document the limitation clearly** in package documentation
2. **Use consistent environment** throughout a project
3. **Restart R session** to switch environments
4. **Use RStudio Projects** for environment isolation (different projects = different R sessions)

### Environment Initialization Timing

Python environment is locked when:

1. `.onLoad()` executes (if using automatic setup)
2. First call to `reticulate::use_virtualenv()`
3. First call to `reticulate::import()`

After any of these, `venv_path` parameters are ignored.

## Package Structure

### Minimal R Package Structure

```
your-package/
├── DESCRIPTION
├── NAMESPACE
├── R/
│   ├── zzz.R              # .onLoad() hook for environment setup
│   ├── utils.R            # get_python_module() helper
│   └── wrappers.R         # Wrapper functions for Python classes
├── man/                   # Documentation
└── README.md
```

### DESCRIPTION File

```
Package: yourpackage
Title: R Interface to Python Package
Version: 0.1.0
Imports: reticulate
Depends: R (>= 3.6.0), memoise
Suggests: testthat
```

**Key dependencies:**
- `reticulate`: Required for Python interoperability
- `memoise`: Recommended for caching module imports

### NAMESPACE File

```
export(PythonClass1)
export(PythonClass2)
export(get_python_module)
import(reticulate)
```

## Best Practices

### 1. Use `delay_load = TRUE`

Always use delayed loading for Python modules:

```r
py_module <- reticulate::import("package", delay_load = TRUE)
```

**Benefits:**
- Faster package loading
- Modules only loaded when actually used
- Reduces startup time

### 2. Cache Module Imports with memoise

```r
get_python_module <- function(venv_path = "./venv") {
  reticulate::use_virtualenv(venv_path, required = TRUE)
  reticulate::import("python_package", delay_load = TRUE)
}

# Cache to avoid repeated imports
get_python_module <- memoise::memoise(get_python_module)
```

### 3. Provide Clear Setup Instructions

Include in README.md:

```markdown
## Installation

### 1. Install R package
```r
remotes::install_github("username/package-name")
```

### 2. Set up Python environment
```bash
uv venv venv
source venv/bin/activate
uv pip install python-package-name
```

### 3. Use the package
```r
library(yourpackage)
obj <- PythonClass(venv_path = "./venv")
```
```

### 4. Handle Python Objects Correctly

Python objects returned by `reticulate` are **proxies**, not R objects:

```r
# Python object proxy
py_obj <- py_module$SomeClass()

# Call Python methods with $
result <- py_obj$fit(X, y)
predictions <- py_obj$predict(X_test)

# Access Python attributes with $
params <- py_obj$params
```

### 5. Document the Python Dependency

Make it clear that Python is required:

```r
#' @section Python Requirements:
#' This function requires Python package 'package-name'.
#' Install with: `pip install package-name`
```

### 6. Provide Fallback Mechanisms

Implement graceful degradation:

```r
.onLoad <- function(libname, pkgname) {
  tryCatch({
    # Try primary method
    setup_python_env()
  }, error = function(e) {
    # Provide helpful error message
    packageStartupMessage(
      "Python environment setup failed.\n",
      "Please install Python and run:\n",
      "  uv venv venv\n",
      "  uv pip install package-name\n",
      "Error: ", e$message
    )
  })
}
```

## Common Pitfalls

### 1. Using Python Objects in Function Defaults

**Problem:**

```r
# ✗ BAD: py_module may not exist yet
PythonClass <- function(optimizer = py_module$Optimizer(), ...) {
  # ...
}
```

**Solution:**

```r
# ✓ GOOD: Use NULL and handle in function body
PythonClass <- function(optimizer = NULL, ...) {
  py_module <- get_python_module(venv_path)
  
  if (is.null(optimizer)) {
    optimizer <- py_module$Optimizer()
  }
  
  py_module$PythonClass(optimizer = optimizer, ...)
}
```

### 2. Forgetting to Export Helper Functions

If users need direct access to Python modules:

```r
# R/utils.R
#' @export
get_python_module <- function(venv_path = "./venv") {
  # ...
}
```

Add to NAMESPACE:
```
export(get_python_module)
```

### 3. Not Handling R to Python Type Conversion

Most conversions are automatic, but be aware:

| R Type | Python Type |
|--------|-------------|
| `numeric` | `float` |
| `integer` | `int` |
| `character` | `str` |
| `logical` | `bool` |
| `matrix` | `numpy.ndarray` |
| `data.frame` | `pandas.DataFrame` |
| `list` | `list` or `dict` |

Force specific types when needed:

```r
# Force integer
param <- as.integer(5)

# Force numpy array
X <- reticulate::np_array(matrix_data)
```

### 4. Assuming venv_path Works After Initialization

Remember: `venv_path` is ignored after Python initializes. Document this clearly.

## Testing Strategies

### Test Python Environment Setup

```r
# tests/testthat/test-setup.R
test_that("Python module can be imported", {
  skip_if_not(reticulate::py_available())
  
  py_module <- get_python_module()
  expect_true(!is.null(py_module))
})
```

### Test Wrapper Functions

```r
test_that("PythonClass wrapper works", {
  skip_if_not(reticulate::py_available())
  
  obj <- PythonClass(param1 = 10)
  expect_s3_class(obj, "python.builtin.object")
})
```

### Use `skip_if_not()` for Python Tests

All tests requiring Python should skip gracefully if Python is unavailable:

```r
skip_if_not(reticulate::py_available())
skip_if_not(reticulate::py_module_available("package_name"))
```

## Decision Tree

```
Start: Need to use Python package in R
│
├─→ Is Python package simple (<500 lines)?
│   └─→ YES: Consider rewriting in native R
│   └─→ NO: Continue
│
├─→ How many functions/classes to wrap?
│   ├─→ 1-5: Use Strategy 1 (Manual wrapping)
│   ├─→ 5-15: Use Strategy 3 (Hybrid wrapping)
│   ├─→ 15-30: Use Strategy 1 or 4 (Manual or Metaprogramming)
│   └─→ 30+: Use Strategy 4 (Metaprogramming)
│
├─→ Who are the users?
│   ├─→ Technical users: Use Strategy 1 (User-managed env)
│   ├─→ Non-technical users: Use Strategy 2 (Automatic env)
│   └─→ Mixed: Use Strategy 3 (Hybrid env)
│
└─→ How often does Python package update?
    ├─→ Rarely: Manual wrapping acceptable
    ├─→ Frequently: Consider metaprogramming
    └─→ Very frequently: Must use metaprogramming or minimal wrapping
```

## Resources

### References

See `references/` for detailed documentation:

- `references/reticulate_api.md` - Complete reticulate API reference
- `references/environment_management.md` - Detailed environment setup patterns
- `references/type_conversion.md` - R-Python type conversion reference

### Example Implementation

See `references/example_package.md` for a complete, working example of an R package that wraps a Python library.

## Quick Start Checklist

- [ ] Decide on environment management strategy (user-managed vs automatic)
- [ ] Decide on wrapping strategy based on number of functions
- [ ] Create R package structure with `usethis::create_package()`
- [ ] Add `reticulate` and `memoise` to DESCRIPTION
- [ ] Implement `get_python_module()` helper function
- [ ] Implement `.onLoad()` if using automatic environment setup
- [ ] Write wrapper functions for Python classes/functions
- [ ] Document Python requirements in README
- [ ] Add tests with appropriate `skip_if_not()` guards
- [ ] Test with fresh R session to verify environment setup
- [ ] Document the single-environment-per-session limitation

## Summary

Porting Python to R using `uv` and `reticulate` enables R users to access Python functionality without reimplementation. Choose environment management and wrapping strategies based on package size, user technical level, and maintenance requirements. Always remember the critical limitation: one Python environment per R session.
