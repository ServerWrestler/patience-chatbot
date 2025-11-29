/**
 * Shared types between main and renderer processes
 */

export interface TestProgress {
  type: 'start' | 'scenario-start' | 'scenario-complete' | 'complete' | 'error';
  data: any;
}

export interface FileResult {
  success: boolean;
  content?: string;
  error?: string;
}

export interface ConfigExample {
  name: string;
  path: string;
  content: any;
}

export interface ValidationResult {
  success: boolean;
  valid?: boolean;
  errors?: string[];
  error?: string;
}
