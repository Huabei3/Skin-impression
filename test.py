import argparse
import torch
import torchvision
from PIL import Image
from torchvision import transforms
from model import QualityGuidedEnhancer


def test(args):
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    model = QualityGuidedEnhancer(
        n_base_1d=args.n_base_1d,
        n_base_3d=args.n_base_3d,
        lut_dim=args.lut_dim,
        use_skin_label=args.use_skin_label,
        backbone_size=args.backbone_size
    ).to(device)

    ckpt = torch.load(args.checkpoint, map_location=device)
    if 'model_state_dict' in ckpt:
        model.load_state_dict(ckpt['model_state_dict'])
    else:
        model.load_state_dict(ckpt)
    model.eval()

    transform = transforms.Compose([
        transforms.Resize((args.img_size, args.img_size)),
        transforms.ToTensor(),
    ])

    img = Image.open(args.input).convert('RGB')
    img_t = transform(img).unsqueeze(0).to(device)

    score = torch.tensor([[args.score]], dtype=torch.float32, device=device)
    label = torch.tensor([[args.label]], dtype=torch.float32, device=device) if args.use_skin_label else None

    with torch.no_grad():
        out = model(img_t, score, label)

    out_img = out.squeeze(0).cpu()
    torchvision.utils.save_image(out_img, args.output)
    print(f"Saved enhanced image to {args.output}")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Inference for Quality-guided Enhancement')
    parser.add_argument('--input', type=str, required=True, help='Path to input raw image')
    parser.add_argument('--output', type=str, required=True, help='Path to save output image')
    parser.add_argument('--checkpoint', type=str, required=True, help='Path to model checkpoint')
    parser.add_argument('--score', type=float, default=0.5, help='Target quality score in [-1, 1]')
    parser.add_argument('--label', type=float, default=5, help='Skin tone label')
    parser.add_argument('--img_size', type=int, default=256, help='Image resize size')
    parser.add_argument('--backbone_size', type=int, default=256, help='Backbone input size (must match training)')
    parser.add_argument('--n_base_1d', type=int, default=3)
    parser.add_argument('--n_base_3d', type=int, default=3)
    parser.add_argument('--lut_dim', type=int, default=33)
    parser.add_argument('--use_skin_label', action='store_true', default=True)
    parser.add_argument('--no_skin_label', dest='use_skin_label', action='store_false')
    args = parser.parse_args()
    test(args)
