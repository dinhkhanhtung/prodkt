// lib/imgbb.js
/**
 * Upload image to ImgBB and return the display URL
 * @param {File} file - Image file to upload
 * @returns {Promise<string>} - The display URL of the uploaded image
 * @throws {Error} - If upload fails
 */
export async function uploadImageToImgBB(file) {
  const apiKey = process.env.NEXT_PUBLIC_IMGBB_API_KEY;
  
  if (!apiKey) {
    throw new Error('ImgBB API key is not configured');
  }

  if (!file) {
    throw new Error('No file provided');
  }

  // Validate file type
  if (!file.type.startsWith('image/')) {
    throw new Error('File must be an image');
  }

  // Validate file size (ImgBB free tier limit is typically 32MB)
  const maxSize = 32 * 1024 * 1024; // 32MB
  if (file.size > maxSize) {
    throw new Error('File size exceeds 32MB limit');
  }

  try {
    // Convert file to base64
    const base64 = await fileToBase64(file);
    
    // Remove data URL prefix if present
    const base64Data = base64.split(',')[1] || base64;

    // Create form data
    const formData = new FormData();
    formData.append('key', apiKey);
    formData.append('image', base64Data);

    // Upload to ImgBB
    const response = await fetch('https://api.imgbb.com/1/upload', {
      method: 'POST',
      body: formData,
    });

    if (!response.ok) {
      throw new Error(`Upload failed with status: ${response.status}`);
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(data.error?.message || 'Upload failed');
    }

    // Return the display URL
    return data.data.display_url;
  } catch (error) {
    console.error('ImgBB upload error:', error);
    throw new Error(error.message || 'Failed to upload image');
  }
}

/**
 * Convert File to base64 string
 * @param {File} file - File to convert
 * @returns {Promise<string>} - Base64 encoded string
 */
function fileToBase64(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = () => resolve(reader.result);
    reader.onerror = (error) => reject(error);
  });
}
