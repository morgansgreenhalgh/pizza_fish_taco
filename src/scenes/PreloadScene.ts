import Phaser from 'phaser';

export class PreloadScene extends Phaser.Scene {
  constructor() {
    super('PreloadScene');
  }

  create(): void {
    this.createPlayerTexture();
    this.createPlayerPortraitTexture();
    this.createBurgerTexture('burger-grunt', 74, 78, 0xbd6a2c);
    this.createBurgerTexture('fry-goblin', 60, 72, 0xf3cc3f);
    this.createBurgerTexture('big-bad-burger', 150, 142, 0x9e4c28);
    this.createAbilityTexture('ability-bite', 0xffcf52, 0x37120e);
    this.createAbilityTexture('ability-spin', 0x38e6ff, 0x161135);
    this.createAbilityTexture('ability-sauce', 0xff4d27, 0x33100b);
    this.createAbilityTexture('ability-jump', 0xb05cff, 0x190b2d);
    this.scene.start('MenuScene');
  }

  private createPlayerTexture(): void {
    const g = this.add.graphics();
    g.lineStyle(5, 0x18090a, 1);
    g.fillStyle(0xf0a736, 1);
    g.fillRoundedRect(18, 26, 88, 62, 12);
    g.strokeRoundedRect(18, 26, 88, 62, 12);
    g.fillStyle(0xffcb5a, 0.9);
    g.fillRoundedRect(26, 34, 58, 16, 8);

    g.lineStyle(4, 0x18090a, 1);
    g.fillStyle(0xf14120, 1);
    g.fillTriangle(26, 24, 88, 6, 108, 36);
    g.strokeTriangle(26, 24, 88, 6, 108, 36);
    g.fillStyle(0xffd66a, 1);
    g.fillTriangle(34, 27, 84, 14, 96, 30);
    g.fillStyle(0xffed8b, 1);
    g.fillCircle(62, 20, 4);
    g.fillCircle(80, 16, 3);

    g.fillStyle(0xffd86b, 1);
    g.fillTriangle(23, 46, 2, 60, 24, 72);
    g.strokeTriangle(23, 46, 2, 60, 24, 72);
    g.fillTriangle(101, 47, 126, 60, 102, 72);
    g.strokeTriangle(101, 47, 126, 60, 102, 72);
    g.fillStyle(0xff4b22, 1);
    g.fillCircle(13, 59, 3);
    g.fillCircle(115, 59, 3);

    g.lineStyle(5, 0x18090a, 1);
    g.fillStyle(0x2d9ce3, 1);
    g.fillEllipse(64, 29, 38, 16);
    g.strokeEllipse(64, 29, 38, 16);
    g.fillStyle(0x1f6ca8, 1);
    g.fillTriangle(51, 28, 34, 16, 44, 39);
    g.fillTriangle(77, 28, 96, 16, 84, 39);

    g.lineStyle(4, 0x18090a, 1);
    g.fillStyle(0xffffff, 1);
    g.fillCircle(48, 54, 9);
    g.fillCircle(74, 54, 9);
    g.fillStyle(0x18090a, 1);
    g.fillCircle(51, 54, 4);
    g.fillCircle(71, 54, 4);
    g.lineStyle(3, 0x18090a, 1);
    g.lineBetween(42, 44, 55, 39);
    g.lineBetween(68, 39, 82, 44);

    g.lineStyle(4, 0x18090a, 1);
    g.fillStyle(0xfff2e2, 1);
    g.fillRoundedRect(46, 70, 34, 13, 2);
    g.strokeRoundedRect(46, 70, 34, 13, 2);
    g.lineStyle(2, 0x18090a, 1);
    g.lineBetween(57, 70, 57, 83);
    g.lineBetween(68, 70, 68, 83);
    g.lineBetween(46, 77, 80, 77);

    g.lineStyle(4, 0x18090a, 1);
    g.fillStyle(0xc55a7e, 1);
    g.fillEllipse(44, 98, 12, 28);
    g.fillEllipse(82, 98, 12, 28);
    g.strokeEllipse(44, 98, 12, 28);
    g.strokeEllipse(82, 98, 12, 28);
    g.fillStyle(0xff9b7a, 1);
    g.fillEllipse(38, 108, 24, 8);
    g.fillEllipse(88, 108, 24, 8);
    g.strokeEllipse(38, 108, 24, 8);
    g.strokeEllipse(88, 108, 24, 8);

    g.lineStyle(2, 0x8f5a1d, 0.4);
    for (let i = 0; i < 18; i += 1) {
      g.fillStyle(0xffc45b, 0.5);
      g.fillCircle(28 + ((i * 19) % 68), 38 + ((i * 13) % 42), 1.5);
    }

    g.generateTexture('pizza-fish-taco', 128, 116);
    g.destroy();
  }

  private createBurgerTexture(key: string, width: number, height: number, color: number): void {
    const g = this.add.graphics();
    const outline = 0x160707;
    g.lineStyle(Math.max(4, width * 0.04), outline, 1);
    g.fillStyle(0xf0b14b, 1);
    g.fillEllipse(width / 2, height * 0.35, width * 0.86, height * 0.42);
    g.strokeEllipse(width / 2, height * 0.35, width * 0.86, height * 0.42);
    g.fillStyle(0xffeb91, 1);
    for (let i = 0; i < 5; i += 1) {
      g.fillCircle(width * (0.25 + i * 0.12), height * (0.2 + (i % 2) * 0.05), Math.max(1.5, width * 0.025));
    }
    g.fillStyle(0x4f2214, 1);
    g.fillRect(width * 0.16, height * 0.39, width * 0.68, height * 0.12);
    g.fillStyle(color, 1);
    g.fillEllipse(width / 2, height * 0.56, width * 0.82, height * 0.28);
    g.strokeEllipse(width / 2, height * 0.56, width * 0.82, height * 0.28);
    g.fillStyle(0xffdf6c, 1);
    g.fillRect(width * 0.18, height * 0.49, width * 0.64, height * 0.09);
    g.fillStyle(0xf0b14b, 1);
    g.fillEllipse(width / 2, height * 0.68, width * 0.78, height * 0.28);
    g.strokeEllipse(width / 2, height * 0.68, width * 0.78, height * 0.28);
    g.fillStyle(0xffffff, 1);
    g.fillCircle(width * 0.36, height * 0.34, width * 0.07);
    g.fillCircle(width * 0.62, height * 0.34, width * 0.07);
    g.fillStyle(0x140b0c, 1);
    g.fillCircle(width * 0.38, height * 0.34, width * 0.035);
    g.fillCircle(width * 0.6, height * 0.34, width * 0.035);
    g.lineStyle(Math.max(2, width * 0.025), 0x140b0c, 1);
    g.lineBetween(width * 0.28, height * 0.26, width * 0.42, height * 0.22);
    g.lineBetween(width * 0.55, height * 0.22, width * 0.72, height * 0.27);
    g.lineBetween(width * 0.36, height * 0.76, width * 0.64, height * 0.76);
    if (key === 'fry-goblin') {
      g.fillStyle(0xf7d749, 1);
      for (let i = 0; i < 4; i += 1) {
        g.fillRect(width * (0.24 + i * 0.13), height * 0.02, width * 0.08, height * 0.34);
        g.strokeRect(width * (0.24 + i * 0.13), height * 0.02, width * 0.08, height * 0.34);
      }
    }
    if (key === 'big-bad-burger') {
      g.lineStyle(5, 0xffef4a, 1);
      g.strokeCircle(width * 0.5, height * 0.53, width * 0.42);
      g.lineStyle(5, outline, 1);
      g.fillStyle(0xff4d2a, 1);
      g.fillTriangle(width * 0.15, height * 0.08, width * 0.3, height * 0.24, width * 0.2, height * 0.28);
      g.fillTriangle(width * 0.85, height * 0.08, width * 0.7, height * 0.24, width * 0.8, height * 0.28);
      g.strokeTriangle(width * 0.15, height * 0.08, width * 0.3, height * 0.24, width * 0.2, height * 0.28);
      g.strokeTriangle(width * 0.85, height * 0.08, width * 0.7, height * 0.24, width * 0.8, height * 0.28);
    }
    g.generateTexture(key, width, height);
    g.destroy();
  }

  private createPlayerPortraitTexture(): void {
    const g = this.add.graphics();
    g.fillStyle(0x13070b, 1);
    g.fillRoundedRect(0, 0, 72, 72, 4);
    g.lineStyle(4, 0xf6e8c9, 1);
    g.strokeRoundedRect(2, 2, 68, 68, 4);
    g.fillStyle(0xf0a736, 1);
    g.fillRoundedRect(13, 19, 48, 42, 8);
    g.lineStyle(4, 0x160707, 1);
    g.strokeRoundedRect(13, 19, 48, 42, 8);
    g.fillStyle(0xf14120, 1);
    g.fillTriangle(14, 18, 55, 6, 62, 28);
    g.strokeTriangle(14, 18, 55, 6, 62, 28);
    g.fillStyle(0xffffff, 1);
    g.fillCircle(28, 37, 6);
    g.fillCircle(45, 37, 6);
    g.fillStyle(0x160707, 1);
    g.fillCircle(31, 37, 3);
    g.fillCircle(42, 37, 3);
    g.fillStyle(0xfff2e2, 1);
    g.fillRoundedRect(25, 50, 24, 8, 2);
    g.lineStyle(3, 0x160707, 1);
    g.strokeRoundedRect(25, 50, 24, 8, 2);
    g.generateTexture('player-portrait', 72, 72);
    g.destroy();
  }

  private createAbilityTexture(key: string, color: number, backing: number): void {
    const g = this.add.graphics();
    g.fillStyle(backing, 1);
    g.fillRoundedRect(0, 0, 58, 58, 4);
    g.lineStyle(3, 0xf7dfb4, 1);
    g.strokeRoundedRect(2, 2, 54, 54, 4);
    g.lineStyle(5, color, 1);
    g.strokeCircle(29, 29, 16);
    g.fillStyle(color, 0.85);
    g.fillCircle(29, 29, 8);
    g.generateTexture(key, 58, 58);
    g.destroy();
  }
}
