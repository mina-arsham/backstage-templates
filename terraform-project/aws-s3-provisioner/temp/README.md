# Backstage Template File Structure Guide

## 📁 Correct File Structure

Your Backstage template directory should look like this:

```
your-backstage-templates/
└── aws-s3-provisioner/
    ├── template.yaml                 # Backstage template definition
    └── skeleton/                     # Files that get generated
        ├── main.tf                   # Terraform main configuration
        ├── outputs.tf                # Terraform outputs
        ├── README.md                 # Generated project README
        └── catalog-info.yaml         # Backstage catalog entry
```

## 🔄 Two Approaches for Terraform Files

### Approach 1: Static Terraform Files with Variables (Traditional)

**Files in skeleton/:**
- `main.tf` - Uses Terraform variables (`var.project_name`)
- `variables.tf` - Defines all Terraform variables
- `terraform.tfvars` - (Generated separately with values)

**Pros:**
- Standard Terraform workflow
- Can be used outside Backstage
- Easy to test locally
- Supports terraform plan/apply workflow

**Cons:**
- Requires passing values via terraform.tfvars or -var flags
- Extra step to provide values

**Example skeleton/main.tf:**
```hcl
variable "project_name" {
  type = string
}

resource "aws_s3_bucket" "main" {
  bucket = "${var.project_name}-${var.environment}"
}
```

### Approach 2: Templated Terraform Files (Backstage Native)

**Files in skeleton/:**
- `main.tf` - Uses Backstage template syntax (`${{ values.project_name }}`)
- `outputs.tf` - Uses Backstage template syntax
- No `variables.tf` needed
- No `terraform.tfvars` needed

**Pros:**
- Values baked directly into generated files
- No need for separate tfvars file
- Cleaner for one-time provisioning
- Perfect for GitOps workflows

**Cons:**
- Generated files are specific to that instance
- Harder to reuse for multiple environments
- Less flexible for local testing

**Example skeleton/main.tf:**
```hcl
resource "aws_s3_bucket" "main" {
  bucket = "${{ values.project_name }}-${{ values.environment }}"
  
  tags = {
    Environment = "${{ values.environment }}"
    Owner       = "${{ values.owner_email }}"
  }
}
```

## 📝 Template Syntax Reference

### In template.yaml (Backstage Template)
```yaml
parameters:
  - title: Configuration
    properties:
      project_name:
        type: string

steps:
  - id: fetch
    action: fetch:template
    input:
      values:
        project_name: ${{ parameters.project_name }}  # ← Use parameters
```

### In skeleton/* files (Generated Files)
```hcl
# Use values (what gets passed from template.yaml)
resource "aws_s3_bucket" "main" {
  bucket = "${{ values.project_name }}"
}
```

### In regular Terraform files (Not templated)
```hcl
# Use standard Terraform variables
variable "project_name" {
  type = string
}

resource "aws_s3_bucket" "main" {
  bucket = var.project_name
}
```

## 🎯 Recommended Approach for Your Demo

**I recommend Approach 2 (Templated Files)** for your Backstage demo because:

1. ✅ Shows the full power of Backstage templating
2. ✅ Generated repos are immediately usable
3. ✅ No need to explain terraform.tfvars
4. ✅ Values are visible in the generated code
5. ✅ Better for GitOps workflows (each repo is self-contained)

## 📦 Files I'm Providing

I've created **both versions** for you:

### Version 1: Static Terraform (Traditional)
- `main.tf` - Standard Terraform with `var.*`
- `variables.tf` - All variable definitions
- `outputs.tf` - Standard outputs
- `terraform.tfvars.example` - Example values

### Version 2: Templated (Backstage Native) ⭐ **RECOMMENDED FOR DEMO**
- `main.tf.template` - Uses `${{ values.* }}`
- `outputs.tf.template` - Uses `${{ values.* }}`
- No variables.tf needed!
- No terraform.tfvars needed!

## 🚀 How to Use (Templated Approach)

### 1. Set up your template directory:

```bash
mkdir -p /path/to/backstage/templates/aws-s3-provisioner/skeleton
```

### 2. Copy files:

```bash
# Copy the main template
cp template.yaml /path/to/backstage/templates/aws-s3-provisioner/

# Copy the templated Terraform files to skeleton/
cp main.tf.template /path/to/backstage/templates/aws-s3-provisioner/skeleton/main.tf
cp outputs.tf.template /path/to/backstage/templates/aws-s3-provisioner/skeleton/outputs.tf
cp catalog-info.yaml /path/to/backstage/templates/aws-s3-provisioner/skeleton/
```

### 3. Register the template in Backstage:

**Option A: Via UI**
1. Go to Backstage → Create → Register Existing Component
2. Enter the URL or file path to `template.yaml`

**Option B: Via app-config.yaml**
```yaml
catalog:
  locations:
    - type: file
      target: /path/to/templates/aws-s3-provisioner/template.yaml
```

### 4. Test it!

1. Click "Create" in Backstage
2. Select "AWS S3 Bucket Provisioner"
3. Fill out the form
4. Click "Create"
5. Backstage will:
   - Take the values from the form
   - Process `skeleton/main.tf` and replace `${{ values.* }}` with actual values
   - Generate final `main.tf` with hardcoded values
   - Push to GitHub
   - Register in catalog

## 🔍 Example of What Gets Generated

**User fills out form:**
- Project Name: `my-app`
- Environment: `dev`
- AWS Region: `us-east-1`
- Encryption: `AES256`

**Backstage processes skeleton/main.tf:**

Before (template):
```hcl
provider "aws" {
  region = "${{ values.aws_region }}"
}

resource "aws_s3_bucket" "main" {
  bucket = "${{ values.project_name }}-${{ values.environment }}-${random_string.bucket_suffix.result}"
}
```

After (generated):
```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "main" {
  bucket = "my-app-dev-${random_string.bucket_suffix.result}"
}
```

## 🎨 Conditional Rendering with Jinja

The templated files use Jinja2 syntax for conditionals:

```hcl
{%- if values.enable_cors %}
resource "aws_s3_bucket_cors_configuration" "main" {
  # This entire block only appears if enable_cors is true
}
{%- endif %}
```

**Result:**
- If user selects "Enable CORS" → Resource is included
- If user doesn't select it → Resource is completely omitted from generated file

## 📊 Comparison Table

| Feature | Static (Approach 1) | Templated (Approach 2) |
|---------|-------------------|----------------------|
| Reusability | ✅ High | ⚠️ Medium |
| Backstage Demo | ⚠️ Good | ✅ Excellent |
| Local Testing | ✅ Easy | ⚠️ Harder |
| GitOps Ready | ⚠️ Needs tfvars | ✅ Self-contained |
| Maintenance | ⚠️ Two files | ✅ One file |
| Complexity | ⚠️ Higher | ✅ Lower |

## 🎯 My Recommendation

For your **team demo**, use the **templated approach** (Approach 2):

1. Rename the `.template` files:
   ```bash
   mv main.tf.template skeleton/main.tf
   mv outputs.tf.template skeleton/outputs.tf
   ```

2. Show your team how:
   - Form values flow directly into Terraform
   - Conditional resources appear/disappear
   - Generated repos are ready to use
   - No manual variable configuration needed

3. After the demo, if you want to use it in production, you can:
   - Keep the templated approach for simple use cases
   - Switch to static approach for complex scenarios
   - Or provide both options!

## 📚 Additional Resources

- [Backstage Software Templates](https://backstage.io/docs/features/software-templates/)
- [Nunjucks Template Syntax](https://mozilla.github.io/nunjucks/templating.html)
- [Terraform Variables](https://www.terraform.io/language/values/variables)