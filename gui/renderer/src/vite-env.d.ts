/// <reference types="vite/client" />

import { PatienceAPI } from '../../preload';

declare global {
  interface Window {
    patienceAPI: PatienceAPI;
  }
}
