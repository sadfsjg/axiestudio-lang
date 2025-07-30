# 🚀 Axie Studio - Digital Ocean Deployment Guide

## 📋 Pre-Deployment Checklist

### ✅ Repository Status
- [x] All custom scripts moved to `Pythonscript&md` folder
- [x] Repository cleaned for GitHub push
- [x] Digital Ocean App Platform configuration ready
- [x] Environment variables documented
- [x] Database connection tested
- [x] Backend and frontend working locally

### 📁 Repository Structure
```
axie-studio/
├── src/
│   ├── backend/          # Python FastAPI backend
│   └── frontend/         # React TypeScript frontend
├── .do/
│   └── app.yaml         # Digital Ocean App Platform config
├── pyproject.toml       # Python dependencies
├── README.md           # Project documentation
├── LICENSE             # MIT License
└── render.yaml         # Alternative deployment config
```

## 🔧 Digital Ocean App Platform Setup

### Step 1: Create GitHub Repository
1. Create a new repository on GitHub named `axie-studio`
2. Push your clean code:
```bash
git init
git add .
git commit -m "Initial commit: Axie Studio application"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/axie-studio.git
git push -u origin main
```

### Step 2: Digital Ocean App Platform
1. Go to [Digital Ocean App Platform](https://cloud.digitalocean.com/apps)
2. Click "Create App"
3. Choose "GitHub" as source
4. Select your `axie-studio` repository
5. Choose `main` branch
6. Select "Use existing app spec" and upload `.do/app.yaml`

### Step 3: Environment Variables
The following environment variables are automatically configured in `app.yaml`:

```yaml
AXIESTUDIO_SECRET_KEY: R2Rlc3FqTXpxWWVkUlMwU1Nxc2xxT1dZUzE0T2xPZ1VsbDJUalRpZHM=
AXIESTUDIO_AUTO_LOGIN: False
AXIESTUDIO_SUPERUSER: stefan@axiestudio.se
AXIESTUDIO_SUPERUSER_PASSWORD: STEfanjohn!12
AXIESTUDIO_NEW_USER_IS_ACTIVE: True
DATABASE_URL: postgresql://db:AVNS_9f4U8riTaUYdwqimQRC@app-57f1a664-8c39-4f05-99bf-bcf5f51c182a-do-user-24001760-0.h.db.ondigitalocean.com:25060/db?sslmode=require
```

## 🏗️ Application Architecture

### Backend Service (`axiestudio-backend`)
- **Runtime**: Python
- **Command**: `axiestudio run --host 0.0.0.0 --port $PORT --backend-only`
- **Port**: 8080
- **Routes**: `/api`, `/health`, `/health_check`

### Frontend Service (`axiestudio-frontend`)
- **Runtime**: Node.js
- **Build**: `npm install && npm run build`
- **Command**: `npx serve -s build -l $PORT`
- **Port**: 3000
- **Routes**: `/`

## 🔍 Deployment Verification

After deployment, verify these endpoints:

### Backend Health Checks
- `https://your-app.ondigitalocean.app/health` - Should return 200 OK
- `https://your-app.ondigitalocean.app/api/v1/version` - Should return Axie Studio version

### Frontend Access
- `https://your-app.ondigitalocean.app/` - Should load Axie Studio interface

### Admin Access
- Login with: `stefan@axiestudio.se` / `STEfanjohn!12`
- Auto-login is disabled for security

## 🛠️ Troubleshooting

### Common Issues

1. **Build Failures**
   - Check Python dependencies in `pyproject.toml`
   - Verify Node.js version compatibility

2. **Database Connection**
   - Ensure DATABASE_URL is correctly formatted
   - Check Digital Ocean database firewall settings

3. **Environment Variables**
   - Verify all AXIESTUDIO_* variables are set
   - Check for typos in variable names

### Logs Access
- Digital Ocean Console → Your App → Runtime Logs
- Check both backend and frontend service logs

## 📊 Performance Optimization

### Scaling Options
- **Instance Size**: Start with `basic-xxs`, scale up as needed
- **Instance Count**: Increase for high traffic
- **CDN**: Enable for static assets

### Monitoring
- Set up alerts for:
  - Response time > 2s
  - Error rate > 5%
  - Memory usage > 80%

## 🔒 Security Considerations

### Production Security
- [ ] Change default admin password
- [ ] Enable HTTPS (automatic with Digital Ocean)
- [ ] Set up proper CORS policies
- [ ] Configure rate limiting
- [ ] Enable database SSL (already configured)

### Environment Security
- [ ] Rotate SECRET_KEY regularly
- [ ] Use Digital Ocean Secrets for sensitive data
- [ ] Enable audit logging

## 📈 Post-Deployment Tasks

1. **DNS Configuration**
   - Point your domain to Digital Ocean app URL
   - Configure SSL certificate

2. **Monitoring Setup**
   - Set up uptime monitoring
   - Configure error tracking
   - Enable performance monitoring

3. **Backup Strategy**
   - Database backups (Digital Ocean managed)
   - Code backups (GitHub)
   - Configuration backups

## 🎯 Success Criteria

✅ **Deployment Successful When:**
- Backend health endpoint returns 200
- Frontend loads without errors
- Admin login works
- Database connection established
- All Axie Studio branding visible
- No social media links present
- Auto-login properly disabled

---

## 📞 Support

For deployment issues:
1. Check Digital Ocean App Platform logs
2. Verify environment variables
3. Test database connectivity
4. Review GitHub Actions (if enabled)

**Repository**: Clean and ready for production deployment
**Status**: ✅ DEPLOYMENT READY
