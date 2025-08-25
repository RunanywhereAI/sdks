import { EventEmitter } from 'eventemitter3';
import {
  DIContainer,
  Result,
  logger,
  PipelineId,
  SessionId
} from '@runanywhere/core';
import { WebVADService, VAD_SERVICE_TOKEN } from '../services/vad/vad-service';
import { WhisperService, WhisperConfig, TranscriptionResult } from '@runanywhere/transcription';
import { LLMService, LLMConfig, CompletionResult } from '@runanywhere/llm';
import { TTSService, TTSConfig, SynthesisResult } from '@runanywhere/tts';

export interface EnhancedPipelineConfig {
  vadConfig?: any;
  whisperConfig?: Partial<WhisperConfig>;
  llmConfig?: Partial<LLMConfig>;
  ttsConfig?: Partial<TTSConfig>;
  enableTranscription?: boolean;
  enableLLM?: boolean;
  enableTTS?: boolean;
  autoPlayTTS?: boolean;
  maxHistorySize?: number;
}

export interface EnhancedPipelineEvents {
  'started': void;
  'stopped': void;
  'error': Error;
  'vadSpeechStart': void;
  'vadSpeechEnd': Float32Array;
  'transcriptionStart': void;
  'partialTranscription': { text: string; timestamp?: number };
  'transcription': TranscriptionResult;
  'llmStart': { prompt: string };
  'llmToken': { token: string; position: number };
  'llmResponse': CompletionResult;
  'ttsStart': { text: string };
  'ttsProgress': { text: string; progress: number };
  'ttsComplete': SynthesisResult;
  'ttsPlaybackStart': void;
  'ttsPlaybackEnd': void;
  'pipelineComplete': {
    transcription: TranscriptionResult;
    llmResponse?: CompletionResult;
    ttsResult?: SynthesisResult;
  };
}

export class EnhancedVoicePipelineManager extends EventEmitter<EnhancedPipelineEvents> {
  private vadService?: WebVADService;
  private whisperService?: WhisperService;
  private llmService?: LLMService;
  private ttsService?: TTSService;
  private isProcessing = false;
  private audioBuffer: Float32Array[] = [];
  private sessionId: SessionId;
  private pipelineId: PipelineId;

  constructor(
    private container: DIContainer,
    private config: EnhancedPipelineConfig = {}
  ) {
    super();
    this.sessionId = crypto.randomUUID() as SessionId;
    this.pipelineId = crypto.randomUUID() as PipelineId;
  }

  async initialize(): Promise<Result<void, Error>> {
    try {
      // Initialize VAD
      this.vadService = await this.container.resolve<WebVADService>(VAD_SERVICE_TOKEN);

      if (!this.vadService) {
        throw new Error('VAD service not found in container');
      }

      // Initialize Whisper if enabled
      if (this.config.enableTranscription !== false) {
        this.whisperService = new WhisperService(this.config.whisperConfig);
        const result = await this.whisperService.initialize();
        if (!result.success) {
          return result;
        }
        logger.info('Whisper service initialized', 'Pipeline');
      }

      // Initialize LLM if enabled
      if (this.config.enableLLM) {
        this.llmService = new LLMService(this.config.llmConfig);
        logger.info('LLM service initialized', 'Pipeline');
      }

      // Initialize TTS if enabled
      if (this.config.enableTTS) {
        this.ttsService = new TTSService(this.config.ttsConfig);
        const result = await this.ttsService.initialize();
        if (!result.success) {
          return result;
        }
        logger.info('TTS service initialized', 'Pipeline');
      }

      this.setupEventHandlers();

      logger.info('Enhanced pipeline initialized', 'Pipeline', {
        sessionId: this.sessionId,
        pipelineId: this.pipelineId,
        transcription: this.config.enableTranscription !== false,
        llm: this.config.enableLLM === true,
        tts: this.config.enableTTS === true
      });

      return Result.ok(undefined);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      logger.error(`Failed to initialize enhanced pipeline: ${err.message}`, 'Pipeline');
      return Result.err(err);
    }
  }

  private setupEventHandlers(): void {
    // VAD events
    if (this.vadService) {
      this.vadService.on('speech_start', () => {
        this.emit('vadSpeechStart');
      });

      this.vadService.on('speech_end', async (audio: Float32Array) => {
        this.emit('vadSpeechEnd', audio);
        await this.processAudio(audio);
      });
    }

    // Whisper events
    if (this.whisperService) {
      this.whisperService.on('partialTranscription', (partial: any) => {
        this.emit('partialTranscription', partial);
      });

      this.whisperService.on('transcriptionStart', () => {
        this.emit('transcriptionStart');
      });
    }

    // LLM events
    if (this.llmService) {
      this.llmService.on('token', (tokenData: any) => {
        this.emit('llmToken', tokenData);
      });

      this.llmService.on('completionStart', (data: any) => {
        this.emit('llmStart', data);
      });
    }

    // TTS events
    if (this.ttsService) {
      this.ttsService.on('synthesisStart', (data: any) => {
        this.emit('ttsStart', data);
      });

      this.ttsService.on('synthesisProgress', (progress: any) => {
        this.emit('ttsProgress', progress);
      });

      this.ttsService.on('synthesisComplete', (result: SynthesisResult) => {
        this.emit('ttsComplete', result);
      });

      this.ttsService.on('playbackStart', () => {
        this.emit('ttsPlaybackStart');
      });

      this.ttsService.on('playbackEnd', () => {
        this.emit('ttsPlaybackEnd');
      });
    }
  }

  private async processAudio(audio: Float32Array): Promise<void> {
    if (this.isProcessing) {
      this.audioBuffer.push(audio);
      return;
    }

    this.isProcessing = true;

    try {
      let transcriptionResult: TranscriptionResult | undefined;
      let llmResult: CompletionResult | undefined;
      let ttsResult: SynthesisResult | undefined;

      // Transcribe audio
      if (this.whisperService) {
        const result = await this.whisperService.transcribe(audio);

        if (result.success) {
          transcriptionResult = result.value;
          this.emit('transcription', transcriptionResult);

          // Process with LLM if enabled
          if (this.llmService && transcriptionResult.text.trim()) {
            const llmResponse = await this.llmService.complete(transcriptionResult.text);

            if (llmResponse.success) {
              llmResult = llmResponse.value;
              this.emit('llmResponse', llmResult);

              // Process with TTS if enabled
              if (this.ttsService && llmResult.text.trim()) {
                const ttsResponse = await this.ttsService.synthesize(llmResult.text);

                if (ttsResponse.success) {
                  ttsResult = ttsResponse.value;

                  // Auto-play if configured
                  if (this.config.autoPlayTTS) {
                    await this.ttsService.play(ttsResult.audioBuffer);
                  }
                }
              }
            }
          }
        } else {
          logger.error(`Transcription failed: ${result.error.message}`, 'Pipeline');
          this.emit('error', result.error);
        }
      }

      // Emit pipeline complete event
      if (transcriptionResult) {
        this.emit('pipelineComplete', {
          transcription: transcriptionResult,
          llmResponse: llmResult,
          ttsResult: ttsResult
        });
      }

      // Process buffered audio
      while (this.audioBuffer.length > 0) {
        const bufferedAudio = this.audioBuffer.shift()!;
        await this.processAudio(bufferedAudio);
      }
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      logger.error(`Audio processing failed: ${err.message}`, 'Pipeline');
      this.emit('error', err);
    } finally {
      this.isProcessing = false;
    }
  }

  async start(): Promise<void> {
    if (!this.vadService) {
      throw new Error('Pipeline not initialized');
    }

    await this.vadService.start();
    this.emit('started');
    logger.info('Enhanced pipeline started', 'Pipeline');
  }

  async stop(): Promise<void> {
    if (this.vadService) {
      this.vadService.stop();
    }

    this.emit('stopped');
    logger.info('Enhanced pipeline stopped', 'Pipeline');
  }

  async pause(): Promise<void> {
    if (this.vadService) {
      await this.vadService.pause();
    }
  }

  async resume(): Promise<void> {
    if (this.vadService) {
      await this.vadService.resume();
    }
  }

  getSessionId(): SessionId {
    return this.sessionId;
  }

  getPipelineId(): PipelineId {
    return this.pipelineId;
  }

  isHealthy(): boolean {
    const vadHealthy = this.vadService?.isHealthy() ?? false;
    const whisperHealthy = this.whisperService?.isHealthy() ?? true;
    const llmHealthy = this.llmService?.isHealthy() ?? true;
    const ttsHealthy = this.ttsService?.isHealthy() ?? true;

    return vadHealthy && whisperHealthy && llmHealthy && ttsHealthy;
  }

  destroy(): void {
    this.vadService?.destroy();
    this.whisperService?.destroy();
    this.llmService?.destroy();
    this.ttsService?.destroy();
    this.removeAllListeners();

    logger.info('Enhanced pipeline destroyed', 'Pipeline');
  }
}
