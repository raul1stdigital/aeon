import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
  // Allow the dev dashboard to be viewed from other devices on the LAN
  // (e.g. recording from a Mac via http://<windows-ip>:5555). Next's dev
  // server otherwise blocks cross-origin asset/RSC requests, leaving the
  // page stuck on "Initializing".
  allowedDevOrigins: ['10.240.15.38', 'localhost'],
}

export default nextConfig
