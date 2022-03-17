import { ensureTrailingSlash, joinUrl } from '../../util/PathUtil';
import type { KeyValueStorage } from './KeyValueStorage';

/**
 * Transforms the keys into relative paths, to be used by the source storage.
 * Encodes the input key with base64 encoding, and prepends it with the stored relative path.
 */
export class EncodingPathStorage<T> implements KeyValueStorage<string, T> {
  private readonly basePath: string;
  private readonly source: KeyValueStorage<string, T>;

  public constructor(relativePath: string, source: KeyValueStorage<string, T>) {
    this.source = source;
    this.basePath = ensureTrailingSlash(relativePath);
  }

  public async get(key: string): Promise<T | undefined> {
    const path = this.createPath(key);
    return this.source.get(path);
  }

  public async has(key: string): Promise<boolean> {
    const path = this.createPath(key);
    return this.source.has(path);
  }

  public async set(key: string, value: T): Promise<this> {
    const path = this.createPath(key);
    await this.source.set(path, value);
    return this;
  }

  public async delete(key: string): Promise<boolean> {
    const path = this.createPath(key);
    return this.source.delete(path);
  }

  public async* entries(): AsyncIterableIterator<[string, T]> {
    for await (const [ path, value ] of this.source.entries()) {
      const key = this.parsePath(path);
      yield [ key, value ];
    }
  }

  /**
   * Converts a key into a path for internal storage.
   */
  private createPath(key: string): string {
    const encodedKey = Buffer.from(key).toString('base64');
    return joinUrl(this.basePath, encodedKey);
  }

  /**
   * Converts an internal storage path string into the original path key.
   */
  private parsePath(path: string): string {
    const buffer = Buffer.from(path.slice(this.basePath.length), 'base64');
    return buffer.toString('utf-8');
  }
}
