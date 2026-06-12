import Phaser from 'phaser';
import type { AttackConfig, Facing } from '../shared/types';

export class AttackHitbox extends Phaser.GameObjects.Rectangle {
  declare readonly body: Phaser.Physics.Arcade.Body;
  readonly attack: AttackConfig;
  readonly owner: Phaser.GameObjects.GameObject;
  private readonly hitTargets = new Set<Phaser.GameObjects.GameObject>();

  constructor(
    scene: Phaser.Scene,
    owner: Phaser.GameObjects.GameObject,
    x: number,
    y: number,
    facing: Facing,
    attack: AttackConfig,
  ) {
    super(scene, x + facing * attack.range * 0.5, y, attack.range, attack.height, 0xffef58, 0.08);
    this.owner = owner;
    this.attack = attack;
    scene.add.existing(this);
    scene.physics.add.existing(this);
    this.body.allowGravity = false;
    this.body.setImmovable(true);
    this.body.setSize(attack.range, attack.height);
    this.setDepth(20);
    scene.time.delayedCall(attack.duration, () => this.destroy());
  }

  canHit(target: Phaser.GameObjects.GameObject): boolean {
    return target !== this.owner && !this.hitTargets.has(target);
  }

  markHit(target: Phaser.GameObjects.GameObject): void {
    this.hitTargets.add(target);
  }
}
