---
name: File Upload
category: feature
language: typescript
framework: nextjs
keywords: [upload, file, image, blob, s3, multipart, drag-drop]
confidence: 0.85
---

# File Upload Pattern

## Problem

File uploads have many complexities:
- Large file handling
- Progress tracking
- Security validation
- Storage management
- Preview and editing

## Solution

Implement secure file uploads with validation, progress tracking, and proper storage integration (Vercel Blob, S3, etc.).

## Implementation

### Basic Upload Component

```typescript
// components/file-upload.tsx
'use client';

import { useState, useRef, useCallback } from 'react';
import { Upload, X, File, Image, Loader2 } from 'lucide-react';
import { Button } from '@/components/ui/button';

interface FileUploadProps {
  accept?: string;
  maxSize?: number; // in bytes
  onUpload: (file: File) => Promise<string>; // Returns URL
  onComplete?: (url: string) => void;
}

export function FileUpload({
  accept = 'image/*',
  maxSize = 5 * 1024 * 1024, // 5MB
  onUpload,
  onComplete,
}: FileUploadProps) {
  const [file, setFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<string | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  const handleFileSelect = useCallback((selectedFile: File) => {
    setError(null);

    // Validate file size
    if (selectedFile.size > maxSize) {
      setError(`File too large. Maximum size is ${maxSize / 1024 / 1024}MB`);
      return;
    }

    setFile(selectedFile);

    // Create preview for images
    if (selectedFile.type.startsWith('image/')) {
      const reader = new FileReader();
      reader.onload = (e) => setPreview(e.target?.result as string);
      reader.readAsDataURL(selectedFile);
    }
  }, [maxSize]);

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    const droppedFile = e.dataTransfer.files[0];
    if (droppedFile) {
      handleFileSelect(droppedFile);
    }
  }, [handleFileSelect]);

  const handleUpload = async () => {
    if (!file) return;

    setIsUploading(true);
    setError(null);

    try {
      const url = await onUpload(file);
      onComplete?.(url);
      setFile(null);
      setPreview(null);
    } catch (err) {
      setError('Upload failed. Please try again.');
    } finally {
      setIsUploading(false);
    }
  };

  const clearFile = () => {
    setFile(null);
    setPreview(null);
    setError(null);
    if (inputRef.current) {
      inputRef.current.value = '';
    }
  };

  return (
    <div className="space-y-4">
      {!file ? (
        <div
          onDrop={handleDrop}
          onDragOver={(e) => e.preventDefault()}
          onClick={() => inputRef.current?.click()}
          className="border-2 border-dashed rounded-lg p-8 text-center cursor-pointer hover:border-blue-500 transition-colors"
        >
          <Upload className="mx-auto h-12 w-12 text-muted-foreground" />
          <p className="mt-2 text-sm text-muted-foreground">
            Drag and drop or click to upload
          </p>
          <p className="text-xs text-muted-foreground mt-1">
            Max size: {maxSize / 1024 / 1024}MB
          </p>
          <input
            ref={inputRef}
            type="file"
            accept={accept}
            onChange={(e) => {
              const file = e.target.files?.[0];
              if (file) handleFileSelect(file);
            }}
            className="hidden"
          />
        </div>
      ) : (
        <div className="border rounded-lg p-4">
          <div className="flex items-start gap-4">
            {preview ? (
              <img
                src={preview}
                alt="Preview"
                className="h-20 w-20 object-cover rounded"
              />
            ) : (
              <div className="h-20 w-20 bg-muted rounded flex items-center justify-center">
                <File className="h-8 w-8 text-muted-foreground" />
              </div>
            )}
            <div className="flex-1 min-w-0">
              <p className="font-medium truncate">{file.name}</p>
              <p className="text-sm text-muted-foreground">
                {(file.size / 1024).toFixed(1)} KB
              </p>
            </div>
            <button onClick={clearFile} className="p-1 hover:bg-muted rounded">
              <X className="h-5 w-5" />
            </button>
          </div>
        </div>
      )}

      {error && (
        <p className="text-red-500 text-sm">{error}</p>
      )}

      {file && (
        <Button
          onClick={handleUpload}
          disabled={isUploading}
          className="w-full"
        >
          {isUploading ? (
            <>
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              Uploading...
            </>
          ) : (
            'Upload'
          )}
        </Button>
      )}
    </div>
  );
}
```

### Upload with Progress

```typescript
// components/file-upload-progress.tsx
'use client';

import { useState, useCallback } from 'react';
import { Progress } from '@/components/ui/progress';

interface UploadWithProgressProps {
  onComplete: (url: string) => void;
}

export function UploadWithProgress({ onComplete }: UploadWithProgressProps) {
  const [progress, setProgress] = useState(0);
  const [isUploading, setIsUploading] = useState(false);

  const uploadFile = useCallback(async (file: File) => {
    setIsUploading(true);
    setProgress(0);

    const formData = new FormData();
    formData.append('file', file);

    const xhr = new XMLHttpRequest();

    xhr.upload.onprogress = (event) => {
      if (event.lengthComputable) {
        const percentComplete = (event.loaded / event.total) * 100;
        setProgress(Math.round(percentComplete));
      }
    };

    xhr.onload = () => {
      if (xhr.status === 200) {
        const response = JSON.parse(xhr.responseText);
        onComplete(response.url);
      }
      setIsUploading(false);
    };

    xhr.onerror = () => {
      setIsUploading(false);
      console.error('Upload failed');
    };

    xhr.open('POST', '/api/upload');
    xhr.send(formData);
  }, [onComplete]);

  return (
    <div>
      <input
        type="file"
        onChange={(e) => {
          const file = e.target.files?.[0];
          if (file) uploadFile(file);
        }}
        disabled={isUploading}
      />
      {isUploading && (
        <div className="mt-4">
          <Progress value={progress} />
          <p className="text-sm text-muted-foreground mt-1">
            {progress}% uploaded
          </p>
        </div>
      )}
    </div>
  );
}
```

### Upload API Route (Vercel Blob)

```typescript
// app/api/upload/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { put } from '@vercel/blob';
import { requireAuth } from '@/lib/auth';

const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
const MAX_SIZE = 10 * 1024 * 1024; // 10MB

export async function POST(request: NextRequest) {
  try {
    const session = await requireAuth();

    const formData = await request.formData();
    const file = formData.get('file') as File | null;

    if (!file) {
      return NextResponse.json(
        { error: 'No file provided' },
        { status: 400 },
      );
    }

    // Validate file type
    if (!ALLOWED_TYPES.includes(file.type)) {
      return NextResponse.json(
        { error: 'Invalid file type' },
        { status: 400 },
      );
    }

    // Validate file size
    if (file.size > MAX_SIZE) {
      return NextResponse.json(
        { error: 'File too large' },
        { status: 400 },
      );
    }

    // Generate unique filename
    const ext = file.name.split('.').pop();
    const filename = `${session.user.id}/${Date.now()}.${ext}`;

    // Upload to Vercel Blob
    const blob = await put(filename, file, {
      access: 'public',
      contentType: file.type,
    });

    return NextResponse.json({
      url: blob.url,
      size: file.size,
      type: file.type,
    });
  } catch (error) {
    console.error('Upload error:', error);
    return NextResponse.json(
      { error: 'Upload failed' },
      { status: 500 },
    );
  }
}
```

### Server Action Upload

```typescript
// actions/upload-actions.ts
'use server';

import { put, del } from '@vercel/blob';
import { revalidatePath } from 'next/cache';
import { requireAuth } from '@/lib/auth';
import { db } from '@/lib/db';

export async function uploadAvatar(formData: FormData) {
  const session = await requireAuth();

  const file = formData.get('avatar') as File;
  if (!file || file.size === 0) {
    return { error: 'No file provided' };
  }

  // Validate
  if (!file.type.startsWith('image/')) {
    return { error: 'File must be an image' };
  }

  if (file.size > 5 * 1024 * 1024) {
    return { error: 'File must be less than 5MB' };
  }

  try {
    // Get current avatar to delete later
    const user = await db.user.findUnique({
      where: { id: session.user.id },
      select: { avatarUrl: true },
    });

    // Upload new avatar
    const blob = await put(
      `avatars/${session.user.id}/${Date.now()}`,
      file,
      { access: 'public' },
    );

    // Update user
    await db.user.update({
      where: { id: session.user.id },
      data: { avatarUrl: blob.url },
    });

    // Delete old avatar
    if (user?.avatarUrl?.includes('vercel-storage.com')) {
      await del(user.avatarUrl).catch(() => {});
    }

    revalidatePath('/profile');

    return { url: blob.url };
  } catch (error) {
    console.error('Avatar upload failed:', error);
    return { error: 'Upload failed' };
  }
}

export async function deleteUpload(url: string) {
  const session = await requireAuth();

  // Verify ownership
  const file = await db.file.findFirst({
    where: {
      url,
      userId: session.user.id,
    },
  });

  if (!file) {
    return { error: 'File not found' };
  }

  try {
    await del(url);
    await db.file.delete({ where: { id: file.id } });
    return { success: true };
  } catch (error) {
    return { error: 'Delete failed' };
  }
}
```

### Multiple File Upload

```typescript
// components/multi-file-upload.tsx
'use client';

import { useState, useCallback } from 'react';
import { X, Upload, CheckCircle, AlertCircle } from 'lucide-react';

interface FileState {
  file: File;
  status: 'pending' | 'uploading' | 'success' | 'error';
  progress: number;
  url?: string;
  error?: string;
}

export function MultiFileUpload({
  onComplete,
  maxFiles = 10,
}: {
  onComplete: (urls: string[]) => void;
  maxFiles?: number;
}) {
  const [files, setFiles] = useState<FileState[]>([]);

  const addFiles = useCallback((newFiles: FileList) => {
    const remaining = maxFiles - files.length;
    const filesToAdd = Array.from(newFiles).slice(0, remaining);

    setFiles((prev) => [
      ...prev,
      ...filesToAdd.map((file) => ({
        file,
        status: 'pending' as const,
        progress: 0,
      })),
    ]);
  }, [files.length, maxFiles]);

  const uploadFile = async (index: number) => {
    const fileState = files[index];
    if (fileState.status !== 'pending') return;

    setFiles((prev) =>
      prev.map((f, i) =>
        i === index ? { ...f, status: 'uploading' } : f
      ),
    );

    const formData = new FormData();
    formData.append('file', fileState.file);

    try {
      const response = await fetch('/api/upload', {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) throw new Error('Upload failed');

      const { url } = await response.json();

      setFiles((prev) =>
        prev.map((f, i) =>
          i === index ? { ...f, status: 'success', url, progress: 100 } : f
        ),
      );
    } catch (error) {
      setFiles((prev) =>
        prev.map((f, i) =>
          i === index
            ? { ...f, status: 'error', error: 'Upload failed' }
            : f
        ),
      );
    }
  };

  const uploadAll = async () => {
    const pendingIndexes = files
      .map((f, i) => (f.status === 'pending' ? i : -1))
      .filter((i) => i !== -1);

    await Promise.all(pendingIndexes.map(uploadFile));

    const urls = files
      .filter((f) => f.status === 'success' && f.url)
      .map((f) => f.url!);

    if (urls.length > 0) {
      onComplete(urls);
    }
  };

  const removeFile = (index: number) => {
    setFiles((prev) => prev.filter((_, i) => i !== index));
  };

  return (
    <div className="space-y-4">
      <div
        onDrop={(e) => {
          e.preventDefault();
          addFiles(e.dataTransfer.files);
        }}
        onDragOver={(e) => e.preventDefault()}
        className="border-2 border-dashed rounded-lg p-8 text-center"
      >
        <Upload className="mx-auto h-12 w-12 text-muted-foreground" />
        <p className="mt-2">Drag and drop files here</p>
        <input
          type="file"
          multiple
          onChange={(e) => e.target.files && addFiles(e.target.files)}
          className="hidden"
          id="file-input"
        />
        <label htmlFor="file-input" className="cursor-pointer text-blue-600">
          or browse
        </label>
      </div>

      {files.length > 0 && (
        <ul className="space-y-2">
          {files.map((fileState, index) => (
            <li
              key={index}
              className="flex items-center gap-3 p-3 border rounded"
            >
              <span className="flex-1 truncate">{fileState.file.name}</span>

              {fileState.status === 'success' && (
                <CheckCircle className="h-5 w-5 text-green-500" />
              )}
              {fileState.status === 'error' && (
                <AlertCircle className="h-5 w-5 text-red-500" />
              )}
              {fileState.status === 'uploading' && (
                <span className="text-sm">{fileState.progress}%</span>
              )}

              <button onClick={() => removeFile(index)}>
                <X className="h-5 w-5" />
              </button>
            </li>
          ))}
        </ul>
      )}

      {files.some((f) => f.status === 'pending') && (
        <button
          onClick={uploadAll}
          className="w-full py-2 bg-blue-600 text-white rounded"
        >
          Upload All
        </button>
      )}
    </div>
  );
}
```

## When to Use

- User avatars/profile pictures
- Document uploads
- Media galleries
- File attachments

## Anti-patterns

```typescript
// BAD: No file validation
const file = formData.get('file');
await put(file.name, file); // No type/size check!

// BAD: Exposing internal paths
return { path: `/tmp/uploads/${filename}` }; // Security risk!

// BAD: No authentication
export async function POST(req) {
  const file = await req.formData(); // Anyone can upload!
}

// BAD: Synchronous large file handling
const buffer = await file.arrayBuffer(); // Memory issues
```

```typescript
// GOOD: Validate everything
if (!ALLOWED_TYPES.includes(file.type)) return error;
if (file.size > MAX_SIZE) return error;

// GOOD: Use CDN URLs
return { url: blob.url }; // Public CDN URL

// GOOD: Require authentication
const session = await requireAuth();
const filename = `${session.user.id}/${uuid()}`;

// GOOD: Stream large files
const stream = file.stream();
await put(filename, stream, { ... });
```

## Related Patterns

- Server Action Pattern - For upload actions
- API Route Pattern - For upload endpoints
- Validation Pattern - For file validation
