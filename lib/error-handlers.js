/**
 * Error Handlers Library for n8n Job Marketing Workflow
 *
 * Reusable functions for validation, error handling, and retry logic.
 * Copy these functions into n8n Code nodes as needed.
 *
 * @version 1.0.0
 * @author Claude AI
 * @date 2025-12-12
 */

// ============================================================================
// INPUT VALIDATION
// ============================================================================

/**
 * Validates job data from Airtable trigger
 * Use in: Parse Data node (node 2)
 *
 * @param {Object} fields - Airtable record fields
 * @param {string} recordId - Airtable record ID
 * @returns {Object} - { valid: boolean, data: Object|null, error: string|null }
 */
function validateJobInput(fields, recordId) {
  const errors = [];

  // Extract fields with fallbacks
  const jobTitle = (fields['Vacaturetitel'] || '').trim();
  const jobTitleEN = (fields['Functietitel EN'] || jobTitle).trim();
  const description = (fields['Omschrijving'] || '').trim();
  const requirements = (fields['Requirements'] || '').trim();
  const location = (fields['Locatie'] || 'Nederland').trim();
  const seniority = fields['Senioriteit'] || 'Medior';
  const salary = (fields['Salaris'] || 'Marktconform').trim();
  const usps = (fields['USPs'] || '').trim();

  // Required field validation
  if (!jobTitle) {
    errors.push('Vacaturetitel is verplicht');
  }

  if (!description) {
    errors.push('Omschrijving is verplicht');
  }

  // Minimum length validation
  if (description && description.length < 100) {
    errors.push(`Omschrijving te kort (${description.length} chars, min 100 nodig)`);
  }

  if (jobTitle && jobTitle.length < 5) {
    errors.push(`Vacaturetitel te kort (${jobTitle.length} chars, min 5 nodig)`);
  }

  // Character limit validation (prevent token overflow)
  if (description && description.length > 5000) {
    errors.push(`Omschrijving te lang (${description.length} chars, max 5000)`);
  }

  // Seniority enum validation
  const validSeniority = ['Junior', 'Medior', 'Senior'];
  if (!validSeniority.includes(seniority)) {
    errors.push(`Ongeldige Senioriteit: ${seniority} (moet zijn: ${validSeniority.join(', ')})`);
  }

  // If validation failed, return error
  if (errors.length > 0) {
    return {
      valid: false,
      data: null,
      error: errors.join('; '),
      recordId
    };
  }

  // Return validated data
  return {
    valid: true,
    error: null,
    recordId,
    data: {
      recordId,
      jobTitle,
      jobTitleEN,
      description,
      requirements,
      location,
      seniority,
      salary,
      usps
    }
  };
}

// ============================================================================
// OUTPUT PARSING & VALIDATION
// ============================================================================

/**
 * Parses and validates Claude API response
 * Use in: Parse Output node (node 4)
 *
 * @param {Object} claudeResponse - Raw response from Claude API
 * @param {Object} inputData - Original job data from Parse Data node
 * @returns {Object} - Parsed and validated output
 */
function parseClaudeOutput(claudeResponse, inputData) {
  const result = {
    recordId: inputData.recordId,
    status: 'Error',
    headline1: '',
    headline2: '',
    headline3: '',
    adCopy1: '',
    adCopy2: '',
    targeting: '',
    generatedAt: new Date().toISOString(),
    tokensUsed: 0,
    estimatedCost: '$0.0000',
    qualityIssues: '',
    errorLog: ''
  };

  try {
    // Extract token usage for cost tracking
    const usage = claudeResponse.usage || {};
    const inputTokens = usage.input_tokens || 0;
    const outputTokens = usage.output_tokens || 0;

    // Claude Sonnet 4 pricing (as of Dec 2024)
    // Input: $3 per 1M tokens = $0.000003 per token
    // Output: $15 per 1M tokens = $0.000015 per token
    const costInput = inputTokens * 0.000003;
    const costOutput = outputTokens * 0.000015;
    const totalCost = costInput + costOutput;

    result.tokensUsed = inputTokens + outputTokens;
    result.estimatedCost = `$${totalCost.toFixed(4)}`;

    // Extract and clean content
    let content = claudeResponse.content[0].text;

    // Remove markdown code blocks if present
    content = content
      .replace(/```json\n?/g, '')
      .replace(/```\n?/g, '')
      .trim();

    // Parse JSON
    const generated = JSON.parse(content);

    // Validate required fields exist
    const requiredFields = ['headline_1', 'headline_2', 'headline_3', 'ad_copy_1', 'ad_copy_2', 'targeting'];
    const missingFields = requiredFields.filter(field => !generated[field]);

    if (missingFields.length > 0) {
      throw new Error(`Ontbrekende velden in Claude output: ${missingFields.join(', ')}`);
    }

    // Extract headlines and copy
    const h1 = (generated.headline_1 || '').trim();
    const h2 = (generated.headline_2 || '').trim();
    const h3 = (generated.headline_3 || '').trim();
    const copy1 = (generated.ad_copy_1 || '').trim();
    const copy2 = (generated.ad_copy_2 || '').trim();

    // Quality validation
    const qualityIssues = validateContentQuality({
      h1, h2, h3, copy1, copy2
    });

    // Populate result
    result.status = qualityIssues.length > 0 ? 'Review' : 'Done';
    result.headline1 = h1;
    result.headline2 = h2;
    result.headline3 = h3;
    result.adCopy1 = copy1;
    result.adCopy2 = copy2;
    result.targeting = JSON.stringify(generated.targeting, null, 2);
    result.qualityIssues = qualityIssues.join(' | ');
    result.errorLog = '';

  } catch (error) {
    // Parsing failed - log detailed error
    result.status = 'Error';
    result.errorLog = `Parse error: ${error.message}`;

    // Include raw response excerpt for debugging (first 200 chars)
    if (claudeResponse.content && claudeResponse.content[0]) {
      const rawContent = claudeResponse.content[0].text || '';
      result.errorLog += ` | Raw response preview: ${rawContent.substring(0, 200)}...`;
    }
  }

  return result;
}

/**
 * Validates quality of generated content
 *
 * @param {Object} content - Generated headlines and copy
 * @returns {Array<string>} - Array of quality issues found
 */
function validateContentQuality(content) {
  const issues = [];
  const { h1, h2, h3, copy1, copy2 } = content;

  // Character limit validation
  const charLimits = [
    { field: 'Headline 1', value: h1, max: 80 },
    { field: 'Headline 2', value: h2, max: 80 },
    { field: 'Headline 3', value: h3, max: 80 },
    { field: 'Ad Copy 1', value: copy1, max: 350 },
    { field: 'Ad Copy 2', value: copy2, max: 350 }
  ];

  charLimits.forEach(({ field, value, max }) => {
    if (value && value.length > max) {
      issues.push(`${field} te lang (${value.length}/${max} chars)`);
    }
    if (value && value.length < 10) {
      issues.push(`${field} te kort (${value.length} chars)`);
    }
  });

  // Generic phrase detection (Dutch)
  const genericPhrases = [
    'geweldige kans',
    'join ons team',
    'we zoeken',
    'vacature',
    'solliciteer nu',
    'great opportunity',
    'join our team',
    'we are looking',
    'apply now'
  ];

  [h1, h2, h3].forEach((headline, index) => {
    if (!headline) return;

    const lowerHeadline = headline.toLowerCase();
    genericPhrases.forEach(phrase => {
      if (lowerHeadline.includes(phrase)) {
        issues.push(`H${index + 1}: generieke frase "${phrase}"`);
      }
    });
  });

  // Duplicat content check
  if (h1 === h2 || h2 === h3 || h1 === h3) {
    issues.push('Dubbele headlines gedetecteerd');
  }

  if (copy1 === copy2) {
    issues.push('Dubbele ad copy gedetecteerd');
  }

  // Empty content check
  if (!h1 || !h2 || !h3) {
    issues.push('Lege headlines');
  }

  if (!copy1 || !copy2) {
    issues.push('Lege ad copy');
  }

  return issues;
}

// ============================================================================
// RETRY LOGIC WITH EXPONENTIAL BACKOFF
// ============================================================================

/**
 * Executes a function with retry logic
 * Note: n8n HTTP Request nodes have built-in retry. Use this for custom operations.
 *
 * @param {Function} fn - Async function to execute
 * @param {number} maxRetries - Maximum number of retries (default: 3)
 * @param {number} initialDelay - Initial delay in ms (default: 1000)
 * @returns {Promise<any>} - Result of successful execution
 */
async function retryWithBackoff(fn, maxRetries = 3, initialDelay = 1000) {
  let lastError;

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;

      // Don't retry on last attempt
      if (attempt === maxRetries) {
        break;
      }

      // Calculate exponential backoff delay
      const delay = initialDelay * Math.pow(2, attempt);

      // Log retry attempt
      console.log(`Retry attempt ${attempt + 1}/${maxRetries} after ${delay}ms. Error: ${error.message}`);

      // Wait before retrying
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }

  throw lastError;
}

// ============================================================================
// AIRTABLE ERROR LOGGING
// ============================================================================

/**
 * Formats error data for Airtable update
 *
 * @param {string} recordId - Airtable record ID
 * @param {Error|string} error - Error object or message
 * @param {string} nodeName - Name of the node where error occurred
 * @returns {Object} - Formatted error data for Airtable
 */
function formatErrorForAirtable(recordId, error, nodeName) {
  const errorMessage = typeof error === 'string' ? error : error.message;
  const errorStack = typeof error === 'object' && error.stack ? error.stack : '';

  return {
    recordId,
    status: 'Error',
    headline1: '',
    headline2: '',
    headline3: '',
    adCopy1: '',
    adCopy2: '',
    targeting: '',
    generatedAt: new Date().toISOString(),
    tokensUsed: 0,
    estimatedCost: '$0.0000',
    qualityIssues: '',
    errorLog: `[${nodeName}] ${errorMessage}${errorStack ? '\n\nStack: ' + errorStack : ''}`
  };
}

// ============================================================================
// COST MONITORING
// ============================================================================

/**
 * Checks if daily budget limit is exceeded
 * Note: Requires storing daily spend in a persistent location (e.g., Airtable table)
 *
 * @param {number} currentDailyCost - Today's accumulated cost in USD
 * @param {number} dailyLimit - Daily budget limit in USD (default: 5.00)
 * @returns {Object} - { withinBudget: boolean, remaining: number }
 */
function checkDailyBudget(currentDailyCost, dailyLimit = 5.00) {
  const withinBudget = currentDailyCost < dailyLimit;
  const remaining = Math.max(0, dailyLimit - currentDailyCost);

  return {
    withinBudget,
    remaining,
    percentUsed: (currentDailyCost / dailyLimit * 100).toFixed(1),
    shouldAlert: currentDailyCost >= dailyLimit * 0.8 // Alert at 80%
  };
}

/**
 * Calculates token estimate from text length
 * Rough estimate: 1 token ≈ 4 characters for English, ~3 for Dutch
 *
 * @param {string} text - Text to estimate
 * @returns {number} - Estimated token count
 */
function estimateTokens(text) {
  if (!text) return 0;
  // Dutch text tends to be more compact than English
  return Math.ceil(text.length / 3.5);
}

// ============================================================================
// USAGE IN N8N CODE NODES
// ============================================================================

/*
// EXAMPLE: Parse Data node (Validation)
const items = $input.all();
const results = [];

for (const item of items) {
  const fields = item.json.fields;
  const recordId = item.json.id;

  // Use validation function
  const validation = validateJobInput(fields, recordId);

  if (!validation.valid) {
    // Return error status instead of throwing
    results.push({
      json: formatErrorForAirtable(recordId, validation.error, 'Parse Data')
    });
  } else {
    // Valid data - continue to Claude API
    results.push({
      json: validation.data
    });
  }
}

return results;
*/

/*
// EXAMPLE: Parse Output node (With cost tracking & quality validation)
const items = $input.all();
const parseNode = $('Parse Data').all();
const results = [];

for (let i = 0; i < items.length; i++) {
  const response = items[i].json;
  const inputData = parseNode[i].json;

  // Use parsing function with built-in validation
  const result = parseClaudeOutput(response, inputData);
  results.push({ json: result });
}

return results;
*/

/*
// EXAMPLE: Cost monitoring in a separate "Check Budget" node
const allExecutionsToday = $('Update Airtable').all();

let totalCostToday = 0;
allExecutionsToday.forEach(exec => {
  const cost = parseFloat(exec.json.estimatedCost.replace('$', ''));
  totalCostToday += cost;
});

const budget = checkDailyBudget(totalCostToday, 5.00);

if (!budget.withinBudget) {
  throw new Error(`Daily budget exceeded! Spent $${totalCostToday.toFixed(4)} of $5.00`);
}

if (budget.shouldAlert) {
  console.warn(`Budget warning: ${budget.percentUsed}% of daily budget used ($${totalCostToday.toFixed(4)})`);
}

return [{ json: budget }];
*/

// ============================================================================
// EXPORTS (for reference - n8n uses global scope)
// ============================================================================

// In n8n, these functions are defined in the global scope of each Code node.
// Copy the function(s) you need into your Code node along with your logic.
