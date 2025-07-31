# 🐳 Docker Deployment Flows

This project supports **two deployment approaches** depending on your needs:

## 🏆 **Production Flow: Pre-built Images**

**Files:** `docker-compose.yml` + `build-images.sh` + `deploy-vm.sh`

### **How it works:**

```bash
# 1. Build Maven project and create Docker images
./build-images.sh
# Creates: optica/gateway-service:latest, optica/consumer-service:latest

# 2. Deploy using pre-built images
docker-compose up -d
# Uses the tagged images, no building during startup
```

### **Complete deployment:**

```bash
./deploy-vm.sh  # Does both steps above
```

### **Advantages:**

- ✅ **Faster deployments** (no rebuild each time)
- ✅ **Consistent images** across environments
- ✅ **CI/CD ready** (can push to registry)
- ✅ **Production ready** (separate build/deploy phases)
- ✅ **Registry compatible** (can push/pull images)

### **When to use:**

- Production deployments
- CI/CD pipelines
- When you want to push images to registry
- Multiple environment deployments

---

## 🔧 **Development Flow: Build-on-Deploy**

**Files:** `docker-compose.dev.yml`

### **How it works:**

```bash
# Build Maven project
mvn clean install -DskipTests

# Build Docker images and start services in one command
docker-compose -f docker-compose.dev.yml up -d --build
```

### **Advantages:**

- ✅ **Simple single command**
- ✅ **Always fresh build**
- ✅ **Good for development**
- ✅ **Immediate code changes**

### **When to use:**

- Local development
- Testing code changes quickly
- When you don't need image persistence
- Simple proof-of-concept

---

## 📊 **Flow Comparison**

| Aspect               | Production Flow | Development Flow  |
| -------------------- | --------------- | ----------------- |
| **Speed**            | Fast deploys    | Slower (rebuilds) |
| **Consistency**      | High            | Medium            |
| **Simplicity**       | Medium          | High              |
| **CI/CD Ready**      | Yes             | No                |
| **Registry Support** | Yes             | No                |
| **Best for**         | Production      | Development       |

---

## 🚀 **Usage Examples**

### **Production/VM Deployment:**

```bash
# On AWS VM or production server
git clone https://github.com/your-repo/payment-system.git
cd payment-system
./deploy-vm.sh  # Complete deployment
```

### **Local Development:**

```bash
# For quick local testing
git clone https://github.com/your-repo/payment-system.git
cd payment-system
mvn clean install -DskipTests
docker-compose -f docker-compose.dev.yml up -d --build
```

### **Manual Production Steps:**

```bash
# If you want to run steps manually
./build-images.sh                    # Build images
docker-compose down                  # Stop existing
docker-compose up -d                 # Start with pre-built images
```

### **Development with Nginx:**

```bash
# Use production compose but build fresh
./build-images.sh
docker-compose up -d
```

---

## 🔄 **Migration Between Flows**

### **From Development to Production:**

```bash
# Switch from dev to production flow
docker-compose -f docker-compose.dev.yml down
./build-images.sh
docker-compose up -d
```

### **From Production to Development:**

```bash
# Switch from production to dev flow
docker-compose down
docker-compose -f docker-compose.dev.yml up -d --build
```

---

## 🎯 **Recommended Workflow**

### **During Development:**

1. Use `docker-compose.dev.yml` for quick iterations
2. Test changes frequently with `--build` flag

### **Before Production:**

1. Test with production flow: `./build-images.sh && docker-compose up -d`
2. Validate all services are working
3. Push images to registry if needed

### **In Production:**

1. Always use `./deploy-vm.sh` or production flow
2. Keep images tagged and versioned
3. Use health checks and monitoring

---

## 🏷️ **Image Tagging Strategy**

### **Current Setup:**

```bash
optica/gateway-service:latest
optica/consumer-service:latest
```

### **Recommended for Production:**

```bash
# Add versioning to build-images.sh
optica/gateway-service:v1.0.0
optica/gateway-service:latest

optica/consumer-service:v1.0.0
optica/consumer-service:latest
```

### **Registry Usage:**

```bash
# Tag for registry
docker tag optica/gateway-service:latest your-registry/optica/gateway-service:v1.0.0

# Push to registry
docker push your-registry/optica/gateway-service:v1.0.0

# Update docker-compose.yml to use registry images
image: your-registry/optica/gateway-service:v1.0.0
```

---

## ✅ **Current Project Status**

**✅ Fixed Issues:**

- Docker Compose now uses pre-built images in production
- `deploy-vm.sh` calls `build-images.sh` first
- Separated development and production flows
- Clear separation between build and deploy phases

**📁 File Structure:**

```
register-payment/
├── docker-compose.yml          # 🏭 Production (pre-built images)
├── docker-compose.dev.yml      # 🔧 Development (build-on-deploy)
├── build-images.sh            # 🔨 Build script
├── deploy-vm.sh               # 🚀 Production deploy script
└── DOCKER_DEPLOYMENT_FLOWS.md # 📖 This documentation
```

**🎯 The flow is now correct and follows Docker best practices! 🎉**
