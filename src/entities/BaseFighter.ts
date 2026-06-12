import Phaser from 'phaser';
import type { Facing, FighterStats } from '../shared/types';

export abstract class BaseFighter extends Phaser.Physics.Arcade.Sprite {
  declare readonly body: Phaser.Physics.Arcade.Body;
  health: number;
  maxHealth: number;
  damage: number;
  facing: Facing = 1;
  isDead = false;
  isHurt = false;
  scoreValue: number;
  protected moveSpeed: number;
  protected invulnerableUntil = 0;

  protected constructor(
    scene: Phaser.Scene,
    x: number,
    y: number,
    texture: string,
    stats: FighterStats,
  ) {
    super(scene, x, y, texture);
    this.health = stats.health;
    this.maxHealth = stats.maxHealth;
    this.damage = stats.damage;
    this.moveSpeed = stats.moveSpeed;
    this.scoreValue = stats.scoreValue;
    scene.add.existing(this);
    scene.physics.add.existing(this);
    this.setCollideWorldBounds(true);
    this.setDepth(10);
  }

  receiveDamage(amount: number, knockbackX: number, knockbackY: number, sourceX: number): boolean {
    if (this.isDead || this.scene.time.now < this.invulnerableUntil) {
      return false;
    }

    this.health = Math.max(0, this.health - amount);
    const direction = this.x >= sourceX ? 1 : -1;
    this.setVelocity(direction * knockbackX, -knockbackY);
    this.setTintFill(0xffffff);
    this.isHurt = true;
    this.invulnerableUntil = this.scene.time.now + 260;

    this.scene.time.delayedCall(100, () => {
      if (!this.isDead) {
        this.clearTint();
      }
    });

    this.scene.time.delayedCall(260, () => {
      this.isHurt = false;
    });

    if (this.health <= 0) {
      this.die();
    }

    return true;
  }

  protected die(): void {
    this.isDead = true;
    this.setTint(0x555555);
    this.setVelocity(0, -280);
    this.disableBody(false, false);
    this.scene.tweens.add({
      targets: this,
      alpha: 0,
      y: this.y - 20,
      duration: 650,
      onComplete: () => this.destroy(),
    });
  }
}
