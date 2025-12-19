// src/routes/api/ai-assistant/+server.js
export async function POST({ request, locals, platform }) {
  try {
    const { message, artworkId, conversationHistory } = await request.json();
    
    if (!message) {
      return new Response(JSON.stringify({ error: 'Message required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // Build context from database
    const context = await buildContext(platform.env.DB, artworkId, message);
    
    // Create system prompt with context
    const systemPrompt = createSystemPrompt(context);
    
    // Format conversation history
    const messages = [
      { role: 'system', content: systemPrompt },
      ...(conversationHistory || []).slice(-6), // Last 3 exchanges
      { role: 'user', content: message }
    ];
    
    // Call Workers AI
    const aiResponse = await platform.env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
      messages,
      max_tokens: 512,
      temperature: 0.7
    });
    
    return new Response(JSON.stringify({
      response: aiResponse.response || 'I apologize, but I had trouble generating a response. Please try again.'
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('AI Assistant error:', error);
    return new Response(JSON.stringify({ 
      error: 'Failed to process request',
      details: error.message 
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

async function buildContext(db, artworkId, message) {
  const context = {
    artwork: null,
    relatedArtworks: [],
    knowledge: []
  };
  
  try {
    // 1. Get specific artwork if requested
    if (artworkId) {
      const artwork = await db.prepare(
        `SELECT 
          id, title, display_name, type, description, year,
          story_intro, tags
        FROM artworks 
        WHERE id = ? AND published = 1`
      ).bind(artworkId).first();
      
      if (artwork) {
        context.artwork = artwork;
        
        // Get story content if available
        if (artwork.story_intro) {
          const storyContent = await db.prepare(
            `SELECT content_type, content_text
            FROM story_content
            WHERE artwork_id = ?
            ORDER BY order_index`
          ).bind(artworkId).all();
          
          context.artwork.storyContent = storyContent.results;
        }
      }
    }
    
    // 2. Search for relevant artworks based on message keywords
    const keywords = extractKeywords(message);
    if (keywords.length > 0) {
      const keywordQuery = keywords.map(() => 'description LIKE ? OR title LIKE ?').join(' OR ');
      const params = keywords.flatMap(k => [`%${k}%`, `%${k}%`]);
      
      const relatedArtworks = await db.prepare(
        `SELECT id, title, display_name, description, year, type
        FROM artworks
        WHERE (${keywordQuery}) AND published = 1
        LIMIT 5`
      ).bind(...params).all();
      
      context.relatedArtworks = relatedArtworks.results || [];
    }
    
    // 3. Get relevant curated knowledge
    const knowledgeKeywords = extractKnowledgeKeywords(message);
    if (knowledgeKeywords.length > 0) {
      const knowledgeQuery = knowledgeKeywords.map(() => 'topic LIKE ? OR content LIKE ?').join(' OR ');
      const knowledgeParams = knowledgeKeywords.flatMap(k => [`%${k}%`, `%${k}%`]);
      
      const knowledge = await db.prepare(
        `SELECT category, topic, content, artwork_ids
        FROM artist_knowledge
        WHERE ${knowledgeQuery}
        LIMIT 3`
      ).bind(...knowledgeParams).all();
      
      context.knowledge = knowledge.results || [];
    }
    
    // 4. If no specific context, get general knowledge
    if (context.knowledge.length === 0 && !artworkId) {
      const generalKnowledge = await db.prepare(
        `SELECT category, topic, content
        FROM artist_knowledge
        WHERE category IN ('philosophy', 'process')
        ORDER BY created_at DESC
        LIMIT 2`
      ).all();
      
      context.knowledge = generalKnowledge.results || [];
    }
    
  } catch (error) {
    console.error('Context building error:', error);
  }
  
  return context;
}

function createSystemPrompt(context) {
  let prompt = `You are an AI assistant representing Antoine Patraldo, a visual artist who practices daily drawing and storytelling through art. You speak in a warm, thoughtful tone that reflects Antoine's creative philosophy.

IMPORTANT GUIDELINES:
- Speak in first person as if you ARE Antoine (use "I", "my work", etc.)
- Be conversational and personal, not formal or robotic
- If you don't have specific information, be honest but helpful
- Keep responses concise (2-3 paragraphs maximum)
- Focus on the creative process, inspiration, and artistic choices
- Don't make up specific details about artworks you don't have data for

`;

  // Add specific artwork context
  if (context.artwork) {
    prompt += `\nCURRENT ARTWORK BEING DISCUSSED:
Title: ${context.artwork.display_name || context.artwork.title}
Year: ${context.artwork.year}
Type: ${context.artwork.type}
Description: ${context.artwork.description}
`;
    
    if (context.artwork.story_intro) {
      prompt += `Story: ${context.artwork.story_intro}\n`;
    }
  }
  
  // Add related artworks
  if (context.relatedArtworks.length > 0) {
    prompt += `\nRELEVANT ARTWORKS IN MY PORTFOLIO:\n`;
    context.relatedArtworks.forEach(art => {
      prompt += `- "${art.display_name || art.title}" (${art.year}, ${art.type}): ${art.description.substring(0, 100)}...\n`;
    });
  }
  
  // Add curated knowledge
  if (context.knowledge.length > 0) {
    prompt += `\nMY ARTISTIC APPROACH AND PHILOSOPHY:\n`;
    context.knowledge.forEach(k => {
      prompt += `\n${k.topic.replace(/_/g, ' ').toUpperCase()}:\n${k.content}\n`;
    });
  }
  
  prompt += `\nRespond to questions naturally, drawing from this context. If asked about techniques, process, or inspiration, share personal insights. If discussing specific artworks, reference the details provided above.`;
  
  return prompt;
}

function extractKeywords(message) {
  const lowerMessage = message.toLowerCase();
  const keywords = [];
  
  // Art-related terms
  const artTerms = [
    'color', 'palette', 'composition', 'technique', 'style',
    'animation', 'drawing', 'sketch', 'painting', 'illustration',
    'urban', 'landscape', 'portrait', 'abstract', 'figure',
    'winter', 'summer', 'spring', 'autumn', 'night', 'day',
    'architecture', 'city', 'nature', 'people'
  ];
  
  artTerms.forEach(term => {
    if (lowerMessage.includes(term)) {
      keywords.push(term);
    }
  });
  
  // Extract years (2020-2025)
  const yearMatch = message.match(/20[2-9][0-9]/g);
  if (yearMatch) {
    keywords.push(...yearMatch);
  }
  
  return [...new Set(keywords)]; // Remove duplicates
}

function extractKnowledgeKeywords(message) {
  const lowerMessage = message.toLowerCase();
  const keywords = [];
  
  // Process and technique keywords
  const processTerms = [
    'process', 'workflow', 'technique', 'method', 'approach',
    'inspiration', 'inspired', 'influence', 'philosophy',
    'practice', 'routine', 'daily', 'create', 'make',
    'tools', 'software', 'medium', 'materials',
    'color', 'palette', 'composition', 'animation'
  ];
  
  processTerms.forEach(term => {
    if (lowerMessage.includes(term)) {
      keywords.push(term);
    }
  });
  
  return [...new Set(keywords)];
}
